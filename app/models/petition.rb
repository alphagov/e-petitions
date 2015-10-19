require 'textacular/searchable'

class Petition < ActiveRecord::Base
  include PerishableTokenGenerator

  PENDING_STATE     = 'pending'
  VALIDATED_STATE   = 'validated'
  SPONSORED_STATE   = 'sponsored'
  FLAGGED_STATE     = 'flagged'
  OPEN_STATE        = 'open'
  CLOSED_STATE      = 'closed'
  REJECTED_STATE    = 'rejected'
  HIDDEN_STATE      = 'hidden'

  STATES            = %w[pending validated sponsored flagged open closed rejected hidden]
  DEBATABLE_STATES  = %w[open closed]
  VISIBLE_STATES    = %w[open closed rejected]
  SHOW_STATES       = %w[pending validated sponsored flagged open closed rejected]
  MODERATED_STATES  = %w[open closed hidden rejected]
  PUBLISHED_STATES  = %w[open closed]
  SELECTABLE_STATES = %w[open closed rejected hidden]
  SEARCHABLE_STATES = %w[open closed rejected]

  IN_MODERATION_STATES       = %w[sponsored flagged]
  TODO_LIST_STATES           = %w[pending validated sponsored flagged]
  COLLECTING_SPONSORS_STATES = %w[pending validated]
  STOP_COLLECTING_STATES     = %w[pending validated sponsored flagged]

  DEBATE_STATES = %w[pending awaiting debated none closed]

  has_perishable_token called: 'sponsor_token'

  before_save :update_debate_state, if: :scheduled_debate_date_changed?
  after_create :set_petition_on_creator_signature
  after_create :update_last_petition_created_at

  extend Searchable(:action, :background, :additional_details)
  include Browseable

  facet :all,      -> { by_most_popular }
  facet :open,     -> { open_state.by_most_popular }
  facet :rejected, -> { rejected_state.by_most_recent }
  facet :closed,   -> { closed_state.by_most_popular }
  facet :hidden,   -> { hidden_state.by_most_recent }

  facet :awaiting_response,    -> { awaiting_response.by_waiting_for_response_longest }
  facet :with_response,        -> { with_response.by_most_recent_response }

  facet :awaiting_debate,      -> { awaiting_debate.by_most_relevant_debate_date }
  facet :awaiting_debate_date, -> { awaiting_debate_date.by_waiting_for_debate_longest }
  facet :with_debate_outcome,  -> { with_debate_outcome.by_most_recent_debate_outcome }
  facet :debated,              -> { debated.by_most_recent_debate_outcome }
  facet :not_debated,          -> { not_debated.by_most_recent_debate_outcome }

  facet :collecting_sponsors,  -> { collecting_sponsors.by_most_recent }
  facet :in_moderation,        -> { in_moderation.by_most_recent }
  facet :in_debate_queue,      -> { in_debate_queue.by_waiting_for_debate_longest }

  belongs_to :creator_signature, class_name: 'Signature'
  accepts_nested_attributes_for :creator_signature, update_only: true

  has_one :debate_outcome, dependent: :destroy
  has_one :email_requested_receipt, dependent: :destroy
  has_one :government_response, dependent: :destroy
  has_one :note, dependent: :destroy
  has_one :rejection, dependent: :destroy

  has_many :signatures
  has_many :sponsors
  has_many :sponsor_signatures, :through => :sponsors, :source => :signature
  has_many :country_petition_journals, :dependent => :destroy
  has_many :constituency_petition_journals, :dependent => :destroy
  has_many :emails, :dependent => :destroy

  include Staged::Validations::PetitionDetails
  validates_presence_of :open_at, if: :open?
  validates_presence_of :creator_signature, on: :create
  validates_inclusion_of :state, in: STATES

  with_options allow_nil: true, prefix: true do
    delegate :name, :email, to: :creator_signature, prefix: :creator
    delegate :code, :details, to: :rejection
    delegate :summary, :details, :created_at, :updated_at, to: :government_response
    delegate :date, :transcript_url, :video_url, :overview, to: :debate_outcome, prefix: :debate
  end

  class << self
    def by_most_popular
      reorder(signature_count: :desc, created_at: :desc)
    end

    def by_most_recent
      reorder(created_at: :desc)
    end

    def by_most_recent_debate_outcome
      reorder(debate_outcome_at: :desc, created_at: :desc)
    end

    def by_most_recent_response
      reorder(government_response_at: :desc, created_at: :desc)
    end

    def by_most_relevant_debate_date
      reorder('scheduled_debate_date ASC NULLS LAST, debate_threshold_reached_at ASC NULLS FIRST')
    end

    def by_oldest
      reorder(created_at: :asc)
    end

    def by_waiting_for_debate_longest
      reorder(debate_threshold_reached_at: :asc, created_at: :desc)
    end

    def by_waiting_for_response_longest
      reorder(response_threshold_reached_at: :asc, created_at: :desc)
    end

    def open_state
      where(state: OPEN_STATE)
    end

    def closed_state
      where(state: CLOSED_STATE)
    end

    def hidden_state
      where(state: HIDDEN_STATE)
    end

    def rejected_state
      where(state: REJECTED_STATE)
    end

    def awaiting_debate
      where(debate_state: 'awaiting')
    end

    def awaiting_debate_date
      debate_threshold_reached.not_scheduled
    end

    def awaiting_response
      response_threshold_reached.not_responded
    end

    def collecting_sponsors
      where(state: COLLECTING_SPONSORS_STATES)
    end

    def debate_threshold_reached
      where.not(debate_threshold_reached_at: nil)
    end

    def debateable
      where(state: DEBATABLE_STATES)
    end

    def debated
      where(debate_state: 'debated')
    end

    def for_state(state)
      where(state: state)
    end

    def in_debate_queue
      where(threshold_for_debate_reached.or(scheduled_for_debate))
    end

    def in_moderation
      where(state: IN_MODERATION_STATES)
    end

    def moderated
      where(state: MODERATED_STATES)
    end

    def not_debated
      where(debate_state: 'none')
    end

    def not_hidden
      where.not(state: HIDDEN_STATE)
    end

    def not_responded
      where(government_response_at: nil)
    end

    def not_scheduled
      where(scheduled_debate_date: nil)
    end

    def respondable
      where(state: RESPONDABLE_STATES)
    end

    def response_threshold_reached
      where.not(response_threshold_reached_at: nil)
    end

    def selectable
      where(state: SELECTABLE_STATES)
    end

    def show
      where(state: SHOW_STATES)
    end

    def threshold
      where(arel_table[:signature_count].gteq(Site.threshold_for_debate))
    end

    def todo_list
      where(state: TODO_LIST_STATES)
    end

    def visible
      where(state: VISIBLE_STATES)
    end

    def with_debate_outcome
      where.not(debate_outcome_at: nil)
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
      limit(limit)
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

    def tagged_with(tag)
      joins(:note).
      where(Note.arel_table['details'].matches("%#{sanitized_tag(tag)}%"))
    end

    def sanitized_tag(tag)
      "[#{tag.gsub(/[\[\]%]/,'')}]"
    end

    def in_need_of_marking_as_debated
      where(awaiting_debate_state.and(debate_date_in_the_past))
    end

    def mark_petitions_as_debated!
      in_need_of_marking_as_debated.update_all(debate_state: 'debated')
    end

    private

    def threshold_for_debate_reached
      arel_table[:debate_threshold_reached_at].not_eq(nil)
    end

    def scheduled_for_debate
      arel_table[:scheduled_debate_date].not_eq(nil)
    end

    def awaiting_debate_state
      arel_table[:debate_state].eq('awaiting')
    end

    def debate_date_in_the_past
      arel_table[:scheduled_debate_date].lt(Date.current)
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

    if pending?
      updates << "state = 'validated'"
    end

    if at_threshold_for_moderation? && collecting_sponsors?
      updates << "moderation_threshold_reached_at = :now"
      updates << "state = 'sponsored'"
    end

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

  def at_threshold_for_moderation?
    unless moderation_threshold_reached_at?
      signature_count >= Site.threshold_for_moderation
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

  def signatures_by_country
    country_petition_journals.to_a.sort_by(&:country)
  end

  def signatures_by_constituency
    constituency_petition_journals.preload(:constituency).to_a.sort_by(&:constituency_id)
  end

  def approve?
    moderation == 'approve'
  end

  def reject?
    moderation == 'reject'
  end

  def flag?
    moderation == 'flag'
  end

  def moderation=(value)
    @moderation = value if value.in?(%w[approve reject flag])
  end

  def moderation
    @moderation
  end

  def moderate(params)
    self.moderation = params[:moderation]

    if approve?
      publish
    elsif reject?
      reject(params[:rejection])
    elsif flag?
      flag
    else
      errors.add :moderation, :blank
      false
    end
  end

  def publish(time = Time.current)
    update(state: OPEN_STATE, open_at: time)
  end

  def reject(attributes)
    build_rejection(attributes) && rejection.save
  end

  def flag
    update(state: FLAGGED_STATE)
  end

  def close!(time = Time.current)
    update!(state: CLOSED_STATE, debate_state: closing_debate_state, closed_at: time)
  end

  def validate_creator_signature!
    if pending?
      creator_signature && creator_signature.validate! && reload
    end
  end

  def count_validated_signatures
    signatures.validated.count
  end

  def collecting_sponsors?
    state.in?(COLLECTING_SPONSORS_STATES)
  end

  def awaiting_moderation?
    state == VALIDATED_STATE
  end

  def in_moderation?
    state.in?(IN_MODERATION_STATES)
  end

  def moderated?
    state.in?(MODERATED_STATES)
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

  def flagged?
    state == FLAGGED_STATE
  end

  def pending?
    state == PENDING_STATE
  end

  def published?
    state.in?(PUBLISHED_STATES)
  end

  def can_have_debate_added?
    state.in?(DEBATABLE_STATES)
  end

  def in_todo_list?
    state.in?(TODO_LIST_STATES)
  end

  def government_response?
    government_response_at? && government_response
  end

  def debate_outcome?
    debate_outcome_at? && debate_outcome
  end

  def deadline
    open_at && (closed_at || Site.closed_at_for_opening(open_at))
  end

  # need this callback since the relationship is circular
  def set_petition_on_creator_signature
    creator_signature.update_attribute(:petition_id, id)
  end

  def update_last_petition_created_at
    Site.touch(:last_petition_created_at)
  end

  def supporting_sponsors_count
    sponsors.supporting_the_petition.count
  end

  def has_maximum_sponsors?
    sponsors.count >= Site.maximum_number_of_sponsors && state.in?(STOP_COLLECTING_STATES)
  end

  def update_all(updates)
    self.class.unscoped.where(id: id).update_all(updates)
  end

  def email_requested_receipt!
    email_requested_receipt || create_email_requested_receipt
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

  def awaiting_debate?
    debate_state == 'awaiting'
  end

  def debated?
    debate_state == 'debated'
  end

  def no_debate?
    debate_state == 'none'
  end

  def closing_debate_state
    debate_state == 'pending' ? 'closed' : debate_state
  end

  def update_debate_state
    self.debate_state = evaluate_debate_state
  end

  def evaluate_debate_state
    if scheduled_debate_date?
      scheduled_debate_date > Date.current ? 'awaiting' : 'debated'
    else
      closed? ? 'closed' : 'pending'
    end
  end
end
