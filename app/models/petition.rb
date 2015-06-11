class Petition < ActiveRecord::Base
  include State
  include PerishableTokenGenerator

  has_perishable_token called: 'sponsor_token'

  after_create :set_petition_on_creator_signature

  searchable do
    text :title
    text :action
    text :description
    text :creator_name do
      creator_signature.name
    end
    string :title
    integer :signature_count
    time :closed_at, :trie => true
    time :created_at, :trie => true
    string :state
  end

  # = Relationships =
  belongs_to :creator_signature, :class_name => 'Signature'
  accepts_nested_attributes_for :creator_signature
  has_many :signatures
  has_many :sponsors
  has_many :sponsor_signatures, :through => :sponsors, :source => :signature

  # = Validations =
  include Staged::Validations::PetitionDetails
  validates_presence_of :response, :if => :email_signees, :message => "must be completed when email signees is checked"
  validates_presence_of :open_at, :closed_at, :if => :open?
  validates_presence_of :rejection_code, :if => :rejected?
  # Note: we only validate creator_signature on create since if we always load creator_signature on validation then
  # when we save a petition, the after_update on the creator_signature gets fired. An overhead that is unecesssary.
  validates_presence_of :creator_signature, :message => "%{attribute} must be completed", :on => :create
  validates_inclusion_of :state, :in => STATES, :message => "'%{value}' not recognised"

  attr_accessor :email_signees

  # = Finders =
  scope :threshold, -> { where('signature_count >= ? OR response_required = ?', SystemSetting.value_of_key(SystemSetting::THRESHOLD_SIGNATURE_COUNT).to_i, true) }

  scope :for_state, ->(state) {
    if CLOSED_STATE.casecmp(state) == 0
      where('state = ? AND closed_at < ?', OPEN_STATE, Time.current)
    elsif OPEN_STATE.casecmp(state) == 0
      where('state = ? AND closed_at >= ?', OPEN_STATE, Time.current)
    else
      where(state: state)
    end
  }
  scope :visible, -> { where(state: VISIBLE_STATES) }
  scope :moderated, -> { where(state: MODERATED_STATES) }
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

  def self.update_all_signature_counts
    Petition.visible.each do |petition|
      petition_current_count = petition.count_validated_signatures
      if petition_current_count != petition.signature_count
        petition.update_attribute(:signature_count, petition_current_count)
      end
    end
  end

  def self.counts_by_state
    counts_by_state = {}
    states = State::STATES + [CLOSED_STATE]
    states.each do |key_name|
      counts_by_state[key_name.to_sym] = for_state(key_name.to_s).count
    end
    counts_by_state
  end

  def publish!
    self.state = Petition::OPEN_STATE
    self.open_at = Time.current
    self.closed_at = AppConfig.petition_duration.months.from_now.end_of_day
    save!
  end

  def count_validated_signatures
    signatures.validated.count
  end

  def need_emailing
    signatures.need_emailing(email_requested_at)
  end

  def awaiting_moderation?
    self.state == VALIDATED_STATE
  end

  def in_moderation?
    self.state == SPONSORED_STATE
  end

  def collecting_sponsors?
    self.state == VALIDATED_STATE || self.state == PENDING_STATE
  end

  def open?
    self.state == OPEN_STATE
  end

  def can_be_signed?
    self.state == OPEN_STATE and self.closed_at > Time.current
  end

  def rejected?
    self.state == REJECTED_STATE
  end

  def hidden?
    self.state == HIDDEN_STATE
  end

  def closed?
    self.state == OPEN_STATE && self.closed_at <= Time.current
  end

  def state_label
    if (self.closed?)
      CLOSED_STATE
    else
      self.state
    end
  end

  def rejection_reason
    RejectionReason.for_code(self.rejection_code).title
  end

  def rejection_description
    RejectionReason.for_code(self.rejection_code).description
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

  # need this callback since the relationship is circular
  def set_petition_on_creator_signature
    self.creator_signature.update_attribute(:petition_id, self.id)
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
    supporting_sponsors_count == AppConfig.sponsor_moderation_threshold
  end

  def below_sponsor_moderation_threshold?
    supporting_sponsors_count < AppConfig.sponsor_moderation_threshold
  end

  def validate_creator_signature!
    self.creator_signature.update_attribute(:state, Signature::VALIDATED_STATE) if creator_signature.state == Signature::PENDING_STATE
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
    sponsors.count >= AppConfig.sponsor_count_max && stop_collecting_sponsors_states
  end

  def stop_collecting_sponsors_states
    state == SPONSORED_STATE || state == VALIDATED_STATE || state == PENDING_STATE
  end
end
