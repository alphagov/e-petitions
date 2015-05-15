# == Schema Information
#
# Table name: petitions
#
#  id                      :integer(4)      not null, primary key
#  title                   :string(255)     not null
#  description             :text
#  response                :text
#  state                   :string(10)      default("pending"), not null
#  open_at                 :datetime
#  department_id           :integer(4)
#  creator_signature_id    :integer(4)      not null
#  created_at              :datetime
#  updated_at              :datetime
#  creator_id              :integer(4)
#  rejection_text          :text
#  closed_at               :datetime
#  signature_count         :integer(4)      default(0)
#  response_required       :boolean(1)      default(FALSE)
#  internal_response       :text
#  rejection_code          :string(50)
#  notified_by_email       :boolean(1)      default(FALSE)
#  email_requested_at      :datetime
#  get_an_mp_email_sent_at :datetime
#

class Petition < ActiveRecord::Base
  include State

  after_create :set_petition_on_creator_signature

  searchable do
    text :title
    text :action
    text :description
    text :creator_name do
      creator_signature.name
    end
    text :department_name do
      if department.present?
        department.name
      else
        ''
      end
    end
    integer :department_id
    string :title
    integer :signature_count
    time :closed_at, :trie => true
    time :created_at, :trie => true
    string :state
  end

  # = Relationships =
  belongs_to :department
  belongs_to :creator_signature, :class_name => 'Signature'
  accepts_nested_attributes_for :creator_signature
  has_many :signatures
  has_many :department_assignments
  has_many :sponsors

  # = Validations =
  include Staged::Validations::PetitionDetails
  include Staged::Validations::SponsorDetails
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
  scope :for_departments, ->(departments) { where(department_id: departments.map(&:id)) }
  scope :visible, -> { where(state: VISIBLE_STATES) }
  scope :moderated, -> { where(state: MODERATED_STATES) }
  scope :trending, ->(number_of_days) {
                      joins(:signatures).
                      where("signatures.state" => "validated").
                      where("signatures.updated_at > ?", number_of_days.day.ago).
                      order("count('signatures.id') DESC").
                      group('petitions.id').limit(10)
                    }
  scope :last_hour_trending, -> {
                              joins(:signatures).
                              select("petitions.id as id, count('signatures.id') as signatures_in_last_hour").
                              where("signatures.state" => "validated").
                              where("signatures.updated_at > ?", 1.hour.ago).
                              order("signatures_in_last_hour DESC").
                              group('petitions.id').
                              limit(12)
                            }

  scope :eligible_for_get_an_mp_email, -> {
    where('state = ? and closed_at >= ?', OPEN_STATE, Time.current).
    where(get_an_mp_email_sent_at: nil).
    where("signature_count >= ?", SystemSetting.value_of_key(SystemSetting::GET_AN_MP_SIGNATURE_COUNT).to_i)
  }

  def sponsor_emails
    @sponsor_emails || []
  end

  def sponsor_emails=(emails)
    @sponsor_emails = emails
  end

  def self.update_all_signature_counts
    Petition.visible.each do |petition|
      petition_current_count = petition.count_validated_signatures
      if petition_current_count != petition.signature_count
        petition.update_attribute(:signature_count, petition_current_count)
      end
    end
  end

  def self.email_all_who_passed_finding_mp_threshold
    logger_for_mp_threshold.info('Started')
    Petition.eligible_for_get_an_mp_email.each do |petition|
      logger_for_mp_threshold.info("Email sent: #{petition.creator_signature.email} for #{petition.title}")
      PetitionMailer.ask_creator_to_find_an_mp(petition).deliver_now
      petition.update_attribute(:get_an_mp_email_sent_at, Time.zone.now)
    end
    logger_for_mp_threshold.info('Finished')
  rescue Exception => e
    logger_for_mp_threshold.error("#{e.class.name} while processing email_all_who_passed_finding_mp_threshold: #{e.message}", e)
  end

  def self.logger_for_mp_threshold
    unless @logger_for_mp_threshold
      logfilename = "email_all_who_passed_finding_mp_threshold.log"
      @logger_for_mp_threshold = AuditLogger.new(Rails.root.join('log', logfilename), 'email_all_who_passed_finding_mp_threshold')
    end
    @logger_for_mp_threshold
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
    self.open_at = Time.zone.now
    self.closed_at = AppConfig.petition_duration.months.from_now.end_of_day
    save!
  end

  def reassign!(new_department)
    self.department = new_department
    save!
    department_assignments.create!(:department => new_department, :assigned_on => Time.now)
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

  def open?
    self.state == OPEN_STATE
  end

  def can_be_signed?
    self.state == OPEN_STATE and self.closed_at > Time.zone.now
  end

  def rejected?
    self.state == REJECTED_STATE
  end

  def hidden?
    self.state == HIDDEN_STATE
  end

  def closed?
    self.state == OPEN_STATE && self.closed_at <= Time.zone.now
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
    return true if user.is_a_threshold? || user.is_a_sysadmin?
    return false
  end

  # need this callback since the relationship is circular
  def set_petition_on_creator_signature
    self.creator_signature.update_attribute(:petition_id, self.id)
  end

  def notify_sponsors
    sponsors.each { |s| SponsorMailer.delay.new_sponsor_email(s) }
  end

  def signature_counts_by_postal_district
    Hash.new(0).tap do |counts|
      signatures.validated.find_each do |signature|
        counts[signature.postal_district] += 1 if signature.postal_district.present?
      end
    end
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

  def update_sponsored_state
    update_attribute(:state, SPONSORED_STATE) if self.on_sponsor_moderation_threshold?
  end
end

