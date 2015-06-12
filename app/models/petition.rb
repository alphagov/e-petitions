require 'textacular/searchable'

class Petition < ActiveRecord::Base
  include PerishableTokenGenerator

  PENDING_STATE     = 'pending'
  VALIDATED_STATE   = 'validated'
  SPONSORED_STATE   = 'sponsored'
  OPEN_STATE        = 'open'
  REJECTED_STATE    = 'rejected'
  HIDDEN_STATE      = 'hidden'

  # this is not a state that appears in the state column since a closed petition has
  # a state that is 'open' but the 'closed at' date time is in the past
  CLOSED_STATE      = 'closed'

  STATES            = %w[pending validated sponsored open rejected hidden]
  VISIBLE_STATES    = %w[open rejected]
  MODERATED_STATES  = %w[open hidden rejected]
  SELECTABLE_STATES = %w[open closed rejected hidden]
  SEARCHABLE_STATES = %w[open closed rejected]

  TODO_LIST_STATES           = %w[pending sponsored validated]
  COLLECTING_SPONSORS_STATES = %w[pending validated]

  REJECTION_CODES = %w[no-action duplicate libellous offensive irrelevant honours]
  HIDDEN_REJECTION_CODES = %w[libellous offensive]

  has_perishable_token called: 'sponsor_token'

  before_save :stamp_government_response_at, if: -> { response_summary.present? && response.present? && government_response_at.nil? }
  after_create :set_petition_on_creator_signature

  extend Searchable(:action, :background, :additional_details)
  include Browseable

  facet :all, -> { reorder(signature_count: :desc) }
  facet :open, -> { for_state(OPEN_STATE).reorder(signature_count: :desc) }
  facet :closed, -> { for_state(CLOSED_STATE).reorder(signature_count: :desc) }
  facet :rejected, -> { for_state(REJECTED_STATE).reorder(created_at: :desc) }

  facet :with_response, -> { where(state: OPEN_STATE).with_response.reorder(government_response_at: :desc) }
  facet :with_debate_outcome, -> { preload(:debate_outcome).where(state: OPEN_STATE).with_debate_outcome.reorder("debate_outcomes.debated_on desc") }

  # = Relationships =
  belongs_to :creator_signature, :class_name => 'Signature'
  accepts_nested_attributes_for :creator_signature
  has_many :signatures
  has_many :sponsors
  has_many :sponsor_signatures, :through => :sponsors, :source => :signature
  has_many :constituency_petition_journals, :dependent => :destroy
  has_one :debate_outcome, dependent: :destroy

  # = Validations =
  include Staged::Validations::PetitionDetails
  validates_presence_of :response, :response_summary, :if => :email_signees, :message => "must be completed when email signees is checked"
  validates :response_summary, length: { maximum: 500, message: 'Response summary is too long.' }
  validates_presence_of :open_at, :closed_at, :if => :open?
  validates_presence_of :rejection_code, :if => :rejected?
  validates_inclusion_of :rejection_code, :in => REJECTION_CODES, :if => :rejected?
  # Note: we only validate creator_signature on create since if we always load creator_signature on validation then
  # when we save a petition, the after_update on the creator_signature gets fired. An overhead that is unecesssary.
  validates_presence_of :creator_signature, :message => "%{attribute} must be completed", :on => :create
  validates_inclusion_of :state, :in => STATES, :message => "'%{value}' not recognised"

  attr_accessor :email_signees

  # = Finders =
  scope :threshold, -> { where('signature_count >= ? OR response_required = ?', Site.threshold_for_debate, true) }

  scope :for_state, ->(state) {
    if CLOSED_STATE.casecmp(state) == 0
      where('state = ? AND closed_at < ?', OPEN_STATE, Time.current)
    elsif OPEN_STATE.casecmp(state) == 0
      where('state = ? AND closed_at >= ?', OPEN_STATE, Time.current)
    else
      where(state: state)
    end
  }
  scope :not_hidden, -> { where.not(state: HIDDEN_STATE) }
  scope :visible, -> { where(state: VISIBLE_STATES) }
  scope :moderated, -> { where(state: MODERATED_STATES) }
  scope :selectable, -> { where(state: SELECTABLE_STATES) }
  scope :in_moderation, -> { where(state: SPONSORED_STATE) }
  scope :todo_list, -> { where(state: TODO_LIST_STATES) }
  scope :collecting_sponsors, -> { where(state: COLLECTING_SPONSORS_STATES) }
  scope :trending, ->(number_of_days) {
                      joins(:signatures).
                      where("petitions.state" => "open").
                      where("signatures.state" => "validated").
                      where("signatures.updated_at > ?", number_of_days.day.ago).
                      order("count('signatures.id') DESC").
                      group('petitions.id').limit(10)
                    }
  scope :last_hour_trending, -> {
                              joins(:signatures).
                              select("petitions.*, count('signatures.id') as signatures_in_last_hour").
                              where("petitions.state" => "open").
                              where("signatures.state" => "validated").
                              where("signatures.updated_at > ?", 1.hour.ago).
                              order("signatures_in_last_hour DESC").
                              group('petitions.id').
                              limit(3)
                            }

  scope :by_oldest, -> { order(created_at: :asc) }

  scope :with_response, -> { where.not(response_summary: nil, response: nil) }
  scope :with_debate_outcome, -> { joins(:debate_outcome) }

  def self.counts_by_state
    counts_by_state = {}
    states = STATES + [CLOSED_STATE]
    states.each do |key_name|
      counts_by_state[key_name.to_sym] = for_state(key_name.to_s).count
    end
    counts_by_state
  end

  def self.popular_in_constituency(constituency_id, how_many = 3)
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

  def increment_signature_count(petition_id, time = Time.current)
    sql = "signature_count = signature_count + 1, last_signed_at = ?, updated_at = ?"
    self.class.where(id: id).update_all([sql, time, time])
  end

  def publish!
    update!(state: OPEN_STATE, open_at: Time.current, closed_at: Site.petition_closed_at)
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

  def validate_creator_signature!
    creator_signature && creator_signature.validate! && reload
  end

  def validated_creator_signature?
    creator_signature && creator_signature.validated?
  end

  def count_validated_signatures
    signatures.validated.count
  end

  def need_emailing
    signatures.need_emailing(email_requested_at)
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

  def can_be_signed?
    state == OPEN_STATE && closed_at > Time.current
  end

  def rejected?
    state == REJECTED_STATE
  end

  def hidden?
    state == HIDDEN_STATE
  end

  def closed?
    state == OPEN_STATE && closed_at <= Time.current
  end

  def can_have_debate_added?
    self.open? || self.closed?
  end

  def in_todo_list?
    TODO_LIST_STATES.include? state
  end

  def state_label
    closed? ? CLOSED_STATE : state
  end

  def rejection_reason
    I18n.t(rejection_code.to_sym, scope: :"petitions.rejection_reasons.titles")
  end

  def rejection_description
    I18n.t(rejection_code.to_sym, scope: :"petitions.rejection_reasons.descriptions").strip.html_safe
  end

  def editable_by?(user)
    # NOTE: we can probably just return true here? or refactor this method
    # out of existence
    return true if user.is_a? AdminUser
    return false
  end

  def response_editable_by?(user)
    return true if user.is_a_moderator? || user.is_a_sysadmin?
    return false
  end

  def response_summary_editable_by?(user)
    return true if user.is_a_moderator? || user.is_a_sysadmin?
    return false
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

  def stamp_government_response_at
    self.government_response_at = Time.current
  end
end
