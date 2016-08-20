require 'postcode_sanitizer'

class Signature < ActiveRecord::Base
  include PerishableTokenGenerator

  has_perishable_token
  has_perishable_token called: 'unsubscribe_token'

  PENDING_STATE = 'pending'
  FRAUDULENT_STATE = 'fraudulent'
  VALIDATED_STATE = 'validated'
  INVALIDATED_STATE = 'invalidated'

  STATES = [
    PENDING_STATE, FRAUDULENT_STATE,
    VALIDATED_STATE, INVALIDATED_STATE
  ]

  TIMESTAMPS = {
    'government_response' => :government_response_email_at,
    'debate_scheduled'    => :debate_scheduled_email_at,
    'debate_outcome'      => :debate_outcome_email_at,
    'petition_email'      => :petition_email_at
  }

  # = Relationships =
  belongs_to :petition
  belongs_to :invalidation
  has_one :sponsor

  # = Validations =
  include Staged::Validations::Email
  include Staged::Validations::SignerDetails
  include Staged::Validations::MultipleSigners

  validates_inclusion_of :state, in: STATES
  validates :constituency_id, length: { maximum: 255 }

  before_destroy do
    !creator?
  end

  after_destroy do
    if validated?
      now = Time.current
      ConstituencyPetitionJournal.invalidate_signature_for(self, now)
      CountryPetitionJournal.invalidate_signature_for(self, now)
      petition.decrement_signature_count!(now)
    end
  end

  # = Finders =
  scope :validated, -> { where(state: VALIDATED_STATE) }
  scope :pending, -> { where(state: PENDING_STATE) }
  scope :notify_by_email, -> { where(notify_by_email: true) }
  scope :for_email, ->(email) { where(email: email.downcase) }
  scope :for_name, ->(name) { where("lower(name) = ?", name.downcase) }

  def self.for_invalidating
    where(state: [PENDING_STATE, VALIDATED_STATE])
  end

  def self.for_timestamp(timestamp, since:)
    column = arel_table[column_name_for(timestamp)]
    where(column.eq(nil).or(column.lt(since)))
  end

  def self.need_emailing_for(timestamp, since:)
    validated.notify_by_email.for_timestamp(timestamp, since: since)
  end

  def self.petition_ids_with_invalid_signature_counts
    validated.joins(:petition).
      group([arel_table[:petition_id], Petition.arel_table[:signature_count]]).
      having(arel_table[Arel.star].count.not_eq(Petition.arel_table[:signature_count])).
      pluck(:petition_id)
  end

  def self.column_name_for(timestamp)
    TIMESTAMPS.fetch(timestamp)
  rescue
    raise ArgumentError, "Unknown petition email timestamp: #{timestamp.inspect}"
  end

  def self.fraudulent_domains
    where(state: FRAUDULENT_STATE).
    select("SUBSTRING(email FROM POSITION('@' IN email) + 1) AS domain").
    group("SUBSTRING(email FROM POSITION('@' IN email) + 1)").
    order("COUNT(*) DESC").
    count(:all)
  end

  scope :in_days, ->(number_of_days) { validated.where("updated_at > ?", number_of_days.day.ago) }
  scope :matching, ->(signature) { where(email: signature.email,
                                         name: signature.name,
                                         petition_id: signature.petition_id) }

  # = Methods =
  attr_accessor :uk_citizenship

  def email=(value)
    super(value.to_s.downcase)
  end

  def postcode=(value)
    super(PostcodeSanitizer.call(value))
  end

  def creator?
    petition.creator_signature == self
  end

  def sponsor?
    # avoid loading the object just to check if it's there
    association(:sponsor).scope.exists? # petition.sponsor_signatures.exists? self.id
  end

  def pending?
    state == PENDING_STATE
  end

  def fraudulent?
    state == FRAUDULENT_STATE
  end

  def validated?
    state == VALIDATED_STATE
  end

  def invalidated?
    state == INVALIDATED_STATE
  end

  def unsubscribed?
    notify_by_email == false
  end

  def fraudulent!(now = Time.current)
    retry_lock do
      if pending?
        update_columns(state: FRAUDULENT_STATE, updated_at: now)
      end
    end
  end

  def validate!(now = Time.current)
    update_signature_counts = false

    retry_lock do
      if pending?
        update_signature_counts = true
        petition.validate_creator_signature! unless creator?

        update_columns(
          number:       petition.signature_count + 1,
          state:        VALIDATED_STATE,
          validated_at: now,
          updated_at:   now
        )
      end
    end

    if update_signature_counts
      PetitionSignedDataUpdateJob.perform_later(self)
    end
  end

  def invalidate!(now = Time.current, invalidation_id = nil)
    update_signature_counts = false

    retry_lock do
      if validated?
        update_signature_counts = true
      end

      update_columns(
        state:           INVALIDATED_STATE,
        notify_by_email: false,
        invalidation_id: invalidation_id,
        invalidated_at:  now,
        updated_at:      now
      )
    end

    if update_signature_counts
      ConstituencyPetitionJournal.invalidate_signature_for(self, now)
      CountryPetitionJournal.invalidate_signature_for(self, now)
      petition.decrement_signature_count!(now)
    end
  end

  def mark_seen_signed_confirmation_page!
    update seen_signed_confirmation_page: true
  end

  def unsubscribe!(token)
    if unsubscribed?
      errors.add(:base, "Already Unsubscribed")
    elsif unsubscribe_token != token
      errors.add(:base, "Invalid Unsubscribe Token")
    else
      update(notify_by_email: false)
    end
  end

  def already_unsubscribed?
    errors[:base].include?("Already Unsubscribed")
  end

  def invalid_unsubscribe_token?
    errors[:base].include?("Invalid Unsubscribe Token")
  end

  def constituency
    @constituency ||= Constituency.find_by_postcode(postcode)
  end

  def set_constituency_id
    self.constituency_id = constituency.try(:external_id)
  end

  def store_constituency_id
    set_constituency_id
    save if constituency_id_changed?
  end

  def get_email_sent_at_for(timestamp)
    self[column_name_for(timestamp)]
  end

  def set_email_sent_at_for(timestamp, to: Time.current)
    update_column(column_name_for(timestamp), to)
  end

  def domain
    Mail::Address.new(email).domain
  rescue Mail::Field::ParseError
    nil
  end

  def rate(window = 5.minutes)
    period = Range.new(created_at - window, created_at)
    petition.signatures.where(ip_address: ip_address, created_at: period).count
  end

  private

  def column_name_for(timestamp)
    self.class.column_name_for(timestamp)
  end

  def retry_lock
    retried = false

    begin
      with_lock { yield }
    rescue PG::InFailedSqlTransaction => e
      if retried
        raise e
      else
        retried = true
        self.class.connection.clear_cache!
        retry
      end
    end
  end
end
