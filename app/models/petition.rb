require 'textacular/searchable'

class Petition < ActiveRecord::Base
  include PerishableTokenGenerator

  PENDING_STATE     = 'pending'
  VALIDATED_STATE   = 'validated'
  SPONSORED_STATE   = 'sponsored'
  OPEN_STATE        = 'open'
  CLOSED_STATE      = 'closed'
  REJECTED_STATE    = 'rejected'
  HIDDEN_STATE      = 'hidden'

  STATES            = %w[pending validated sponsored open closed rejected hidden]
  VISIBLE_STATES    = %w[open closed rejected]
  MODERATED_STATES  = %w[open closed hidden rejected]
  SELECTABLE_STATES = %w[open closed rejected hidden]
  SEARCHABLE_STATES = %w[open closed rejected]

  TODO_LIST_STATES           = %w[pending sponsored validated]
  COLLECTING_SPONSORS_STATES = %w[pending validated]

  REJECTION_CODES = %w[no-action duplicate libellous offensive irrelevant honours]
  HIDDEN_REJECTION_CODES = %w[libellous offensive]

  has_perishable_token called: 'sponsor_token'

  after_create :set_petition_on_creator_signature

  extend Searchable(:action, :background, :additional_details)
  include Browseable

  facet :open, -> { for_state(OPEN_STATE).reorder(signature_count: :desc) }
  facet :with_debate_outcome, -> { preload(:debate_outcome).where(state: OPEN_STATE).with_debate_outcome.reorder("debate_outcomes.debated_on desc") }
  facet :awaiting_debate_date, -> { where(state: OPEN_STATE).awaiting_debate_date.without_debate_outcome.reorder(debate_threshold_reached_at: :asc) }
  facet :closed, -> { for_state(CLOSED_STATE).reorder(signature_count: :desc) }
  facet :rejected, -> { for_state(REJECTED_STATE).reorder(created_at: :desc) }
  facet :hidden, -> { for_state(HIDDEN_STATE).reorder(created_at: :desc) }
  facet :all, -> { reorder(signature_count: :desc) }
  facet :collecting_sponsors, -> { collecting_sponsors }
  facet :in_moderation, -> { in_moderation.reorder(created_at: :desc) }
  facet :in_debate_queue, -> { in_debate_queue }

  facet :awaiting_response,    -> { awaiting_response.by_waiting_for_response_longest }
  facet :with_response,        -> { with_response.by_most_recent_response }

  # = Relationships =
  belongs_to :creator_signature, class_name: 'Signature'
  accepts_nested_attributes_for :creator_signature

  has_one :government_response, dependent: :destroy
  has_one :debate_outcome, dependent: :destroy

  has_many :signatures
  has_many :sponsors
  has_many :sponsor_signatures, :through => :sponsors, :source => :signature
  has_many :constituency_petition_journals, :dependent => :destroy

  # = Validations =
  include Staged::Validations::PetitionDetails
  validates_presence_of :open_at, :if => :open?
  validates_presence_of :rejection_code, :if => :rejected?
  validates_inclusion_of :rejection_code, :in => REJECTION_CODES, :if => :rejected?
  # Note: we only validate creator_signature on create since if we always load creator_signature on validation then
  # when we save a petition, the after_update on the creator_signature gets fired. An overhead that is unecesssary.
  validates_presence_of :creator_signature, :message => "%{attribute} must be completed", :on => :create
  validates_inclusion_of :state, :in => STATES, :message => "'%{value}' not recognised"

  # = Finders =
  scope :threshold, -> { where('signature_count >= ?', Site.threshold_for_debate) }
  scope :for_state, ->(state) { where(state: state) }
  scope :not_hidden, -> { where.not(state: HIDDEN_STATE) }
  scope :visible, -> { where(state: VISIBLE_STATES) }
  scope :moderated, -> { where(state: MODERATED_STATES) }
  scope :selectable, -> { where(state: SELECTABLE_STATES) }
  scope :in_moderation, -> { where(state: SPONSORED_STATE) }
  scope :todo_list, -> { where(state: TODO_LIST_STATES) }
  scope :collecting_sponsors, -> { where(state: COLLECTING_SPONSORS_STATES) }
  scope :by_oldest, -> { order(created_at: :asc) }
  scope :with_debate_outcome, -> { joins(:debate_outcome) }
  scope :without_debate_outcome, -> { where.not(id: DebateOutcome.select(:petition_id).uniq) }
  scope :awaiting_debate_date, ->  { where.not(debate_threshold_reached_at: nil) }
  scope :in_debate_queue, -> do
    where(
      arel_table['debate_threshold_reached_at'].not_eq(nil).
      or(
        arel_table['scheduled_debate_date'].not_eq(nil)
      )
    )
  end

  class << self
    def by_most_recent_response
      reorder(government_response_at: :desc)
    end

    def by_waiting_for_response_longest
      reorder(response_threshold_reached_at: :asc)
    end

    def awaiting_response
      response_threshold_reached.not_responded
    end

    def not_responded
      where(government_response_at: nil)
    end

    def respondable
      where(state: RESPONDABLE_STATES)
    end

    def response_threshold_reached
      where.not(response_threshold_reached_at: nil)
    end

    def with_response
      where.not(government_response_at: nil)
    end

    def trending(since = 1.hour.ago, limit = 3)
      select('petitions.*, COUNT(signatures.id) AS signature_count_in_period').
      joins(:signatures).
      where('petitions.state = ?', OPEN_STATE).
      where('petitions.last_signed_at > ?', since).
      where('signatures.validated_at > ?', since).
      group('petitions.id').order('signature_count_in_period DESC').
      limit(3)
    end

    def close_petitions!(time = Time.current)
      in_need_of_closing(time).update_all(state: CLOSED_STATE, closed_at: time, updated_at: time)
    end

    def in_need_of_closing(time = Time.current)
      where(state: OPEN_STATE).where(arel_table[:open_at].lt(Site.opened_at_for_closing(time)))
    end

    def with_invalid_signature_counts
      where(id: Signature.petition_ids_with_invalid_signature_counts).to_a
    end

    def with_invalid_signature_counts
      where(id: Signature.petition_ids_with_invalid_signature_counts).to_a
    end

    def popular_in_constituency(constituency_id, how_many = 50)
      # NOTE: this query is complex, so we'll flatten it at the end
      # to prevent chaining things off the end that might break it.
      self.
        select("#{table_name}.*, #{ConstituencyPetitionJournal.table_name}.signature_count AS constituency_signature_count").
        for_state(OPEN_STATE).
        joins(:constituency_petition_journals).
        merge(ConstituencyPetitionJournal.with_signatures_for(constituency_id).ordered).
        limit(how_many).
        to_a
    end
  end

  def update_signature_count!
    sql = "signature_count = (?), updated_at = ?"
    count = Signature.arel_table[Arel.star].count
    query = Signature.validated.where(petition_id: id).select(count)

    if update_all([sql, query, Time.current]) > 0
      self.reload
    end
  end

  def increment_signature_count!(time = Time.current)
    updates = ["signature_count = signature_count + 1"]
    updates << "last_signed_at = :now"
    updates << "updated_at = :now"

    if at_threshold_for_response?
      updates << "response_threshold_reached_at = :now"
    end

    if at_threshold_for_debate?
      updates << "debate_threshold_reached_at = :now"
    end

    if update_all([updates.join(", "), now: time]) > 0
      self.reload
    end
  end

  def at_threshold_for_response?
    unless response_threshold_reached_at?
      signature_count >= Site.threshold_for_response - 1
    end
  end

  def at_threshold_for_debate?
    unless debate_threshold_reached_at?
      signature_count >= Site.threshold_for_debate - 1
    end
  end

  def publish!(time = Time.current)
    update!(state: OPEN_STATE, open_at: time)
  end

  def reject(attributes)
    assign_attributes(attributes)

    if rejection_code.in?(HIDDEN_REJECTION_CODES)
      self.state = HIDDEN_STATE
    else
      self.state = REJECTED_STATE
    end

    save
  end

  def close!(time = Time.current)
    update!(state: CLOSED_STATE, closed_at: time)
  end

  def validate_creator_signature!
    creator_signature && creator_signature.validate! && reload
  end

  def validated_creator_signature?
    creator_signature && creator_signature.validated?
  end

  def count_validated_signatures
    signatures.validated.count
  end

  def awaiting_moderation?
    state == VALIDATED_STATE
  end

  def in_moderation?
    state == SPONSORED_STATE
  end

  def moderated?
    MODERATED_STATES.include?(state)
  end

  def open?
    state == OPEN_STATE
  end
  alias_method :can_be_signed?, :open?

  def rejected?
    state == REJECTED_STATE
  end

  def hidden?
    state == HIDDEN_STATE
  end

  def closed?
    state == CLOSED_STATE
  end

  def government_responsed?
    government_response_at?
  end

  def can_have_debate_added?
    self.open? || self.closed?
  end

  def in_todo_list?
    TODO_LIST_STATES.include? state
  end

  def deadline
    open_at && (closed_at || Site.closed_at_for_opening(open_at))
  end

  def rejection_reason
    I18n.t(rejection_code.to_sym, scope: :"petitions.rejection_reasons.titles")
  end

  def rejection_description
    I18n.t(rejection_code.to_sym, scope: :"petitions.rejection_reasons.descriptions").strip.html_safe
  end

  # need this callback since the relationship is circular
  def set_petition_on_creator_signature
    creator_signature.update_attribute(:petition_id, id)
  end

  def supporting_sponsors_count
    sponsors.supporting_the_petition.count
  end

  def notify_creator_about_sponsor_support(sponsor)
    raise ArgumentError, 'Not my sponsor' unless sponsors.exists?(sponsor.id)
    raise ArgumentError, 'Not a supporting sponsor' unless sponsor.supports_the_petition?
    if below_sponsor_moderation_threshold?
      SponsorMailer.sponsor_signed_email_below_threshold(self, sponsor).deliver_later
    elsif on_sponsor_moderation_threshold?
      SponsorMailer.sponsor_signed_email_on_threshold(self, sponsor).deliver_later
    end
  end

  def on_sponsor_moderation_threshold?
    supporting_sponsors_count == Site.threshold_for_moderation
  end

  def below_sponsor_moderation_threshold?
    supporting_sponsors_count < Site.threshold_for_moderation
  end

  def update_state_after_new_validated_sponsor!
    if state == PENDING_STATE
      update_attribute(:state, VALIDATED_STATE)
    end

    if on_sponsor_moderation_threshold?
      update_attribute(:state, SPONSORED_STATE)
    end
  end

  def has_maximum_sponsors?
    sponsors.count >= Site.maximum_number_of_sponsors && stop_collecting_sponsors_states
  end

  def stop_collecting_sponsors_states
    state == SPONSORED_STATE || state == VALIDATED_STATE || state == PENDING_STATE
  end

  def update_all(updates)
    self.class.unscoped.where(id: id).update_all(updates)
  end

  def get_email_requested_at_for(name)
    email_requested_receipt!.get(name)
  end
  def set_email_requested_at_for(name, to: Time.current)
    email_requested_receipt!.set(name, to)
  end

  def signatures_to_email_for(name)
    timestamp = get_email_requested_at_for(name)
    raise ArgumentError if timestamp.nil?
    signatures.need_emailing_for(name, since: timestamp)
  end

  has_one :email_requested_receipt, dependent: :destroy
  def email_requested_receipt!
    email_requested_receipt || create_email_requested_receipt
  end
end
