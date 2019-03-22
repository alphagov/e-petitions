require 'active_support/core_ext/digest/uuid'
require 'postcode_sanitizer'

class Signature < ActiveRecord::Base
  include PerishableTokenGenerator

  has_perishable_token
  has_perishable_token called: 'signed_token'
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

  belongs_to :petition
  belongs_to :invalidation

  validates :state, inclusion: { in: STATES }
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, email: { allow_blank: true }, on: :create
  validates :location_code, presence: true
  validates :postcode, presence: true, postcode: true, if: :united_kingdom?
  validates :postcode, length: { maximum: 255 }, allow_blank: true
  validates :uk_citizenship, acceptance: true, unless: :persisted?, allow_nil: false
  validates :constituency_id, length: { maximum: 255 }

  attr_readonly :sponsor, :creator

  before_create if: :email? do
    if find_duplicate
      raise ActiveRecord::RecordNotUnique, "Signature is not unique: #{name}, #{email}, #{postcode}"
    end
  end

  before_create if: :email? do
    self.uuid = generate_uuid
  end

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

  class << self
    def batch(id = 0, limit: 1000)
      where(arel_table[:id].gt(id)).order(id: :asc).limit(limit)
    end

    def by_most_recent
      order(created_at: :desc)
    end

    def column_name_for(timestamp)
      TIMESTAMPS.fetch(timestamp)
    rescue KeyError => e
      raise ArgumentError, "Unknown petition email timestamp: #{timestamp.inspect}"
    end

    def destroy!(signature_ids)
      signatures = find(signature_ids)

      transaction do
        signatures.each do |signature|
          signature.destroy!
        end
      end
    end

    def duplicate(id, email)
      where(arel_table[:id].not_eq(id).and(arel_table[:email].eq(email)))
    end

    def duplicate_emails
      unscoped.from(validated.select(:uuid).group(:uuid).having(arel_table[Arel.star].count.gt(1))).count
    end

    def for_email(email)
      where(email: email.downcase)
    end

    def for_invalidating
      where(state: [PENDING_STATE, VALIDATED_STATE])
    end

    def for_ip(ip)
      where(ip_address: ip)
    end

    def for_name(name)
      where(arel_table[:name].lower.eq(name.downcase))
    end

    def for_timestamp(timestamp, since:)
      column = arel_table[column_name_for(timestamp)]
      where(column.eq(nil).or(column.lt(since)))
    end

    def fraudulent
      where(state: FRAUDULENT_STATE)
    end

    def fraudulent_domains
      where(state: FRAUDULENT_STATE).
      select("SUBSTRING(email FROM POSITION('@' IN email) + 1) AS domain").
      group("SUBSTRING(email FROM POSITION('@' IN email) + 1)").
      order("COUNT(*) DESC").
      count(:all)
    end

    def invalidate!(signature_ids, now = Time.current, invalidation_id = nil)
      signatures = find(signature_ids)

      transaction do
        signatures.each do |signature|
          signature.invalidate!(now, invalidation_id)
        end
      end
    end

    def invalidated
      where(state: INVALIDATED_STATE)
    end

    def missing_constituency_id(since: nil)
      if since
        uk.validated(since: since).where(constituency_id: nil)
      else
        uk.validated.where(constituency_id: nil)
      end
    end

    def need_emailing_for(timestamp, since:)
      validated.subscribed.for_timestamp(timestamp, since: since)
    end

    def pending
      where(state: PENDING_STATE)
    end

    def petition_ids_with_invalid_signature_counts
      validated.joins(:petition).
        group([arel_table[:petition_id], Petition.arel_table[:signature_count]]).
        having(arel_table[Arel.star].count.not_eq(Petition.arel_table[:signature_count])).
        pluck(:petition_id)
    end

    def search(query, options = {})
      query = query.to_s
      page = [options[:page].to_i, 1].max
      scope = by_most_recent

      if ip_search?(query)
        scope = scope.for_ip(query)
      elsif email_search?(query)
        scope = scope.for_email(query)
      else
        scope = scope.for_name(query)
      end

      scope.paginate(page: page, per_page: 50)
    end

    def creator
      where(arel_table[:creator].eq(true))
    end

    def sponsors
      where(arel_table[:sponsor].eq(true))
    end

    def subscribed
      where(notify_by_email: true)
    end

    def trending_domains(since: 1.hour.ago, limit: 20)
      select("SUBSTRING(email FROM POSITION('@' IN email) + 1) AS domain").
      where(arel_table[:validated_at].gt(since)).
      where(arel_table[:invalidated_at].eq(nil)).
      group("SUBSTRING(email FROM POSITION('@' IN email) + 1)").
      order("COUNT(*) DESC").
      limit(limit).
      count(:all)
    end

    def trending_ips(since: 1.hour.ago, limit: 20)
      select(:ip_address).
      where(arel_table[:validated_at].gt(since)).
      where(arel_table[:invalidated_at].eq(nil)).
      group(:ip_address).
      order("COUNT(*) DESC").
      limit(limit).
      count(:all)
    end

    def uk
      where(location_code: "GB")
    end

    def unarchived
      where(archived_at: nil)
    end

    def subscribe!(signature_ids)
      signatures = find(signature_ids)

      transaction do
        signatures.each do |signature|
          signature.update!(notify_by_email: true)
        end
      end
    end

    def unsubscribe!(signature_ids)
      signatures = find(signature_ids)

      transaction do
        signatures.each do |signature|
          if signature.creator?
            raise RuntimeError, "Can't unsubscribe the creator signature"
          elsif signature.pending?
            raise RuntimeError, "Can't unsubscribe a pending signature"
          else
            signature.update!(notify_by_email: false)
          end
        end
      end
    end

    def validate!(signature_ids, now = Time.current)
      signatures = find(signature_ids)

      transaction do
        signatures.each do |signature|
          signature.validate!(now)
        end
      end
    end

    def validated(since: nil)
      if since
        where(state: VALIDATED_STATE).where(validated_at.gt(since))
      else
        where(state: VALIDATED_STATE)
      end
    end

    def validated?(id)
      where(id: id).where(validated_at.not_eq(nil)).exists?
    end

    private

    def ip_search?(query)
      /\A(?:\d{1,3}){1}(?:\.\d{1,3}){3}\z/ =~ query
    end

    def email_search?(query)
      query.include?('@')
    end

    def validated_at
      arel_table[:validated_at]
    end
  end

  attr_accessor :uk_citizenship

  def find_duplicate
    return nil unless petition

    signatures = petition.signatures.duplicate(id, email)
    return signatures.first if signatures.many?

    if signature = signatures.first
      if sanitized_name == signature.sanitized_name
        signature
      elsif postcode != signature.postcode
        signature
      end
    end
  end

  def find_duplicate!
    find_duplicate || (raise ActiveRecord::RecordNotFound, "Signature not found: #{name}, #{email}, #{postcode}")
  end

  def name=(value)
    super(value.to_s.strip)
  end

  def email=(value)
    super(value.to_s.strip.downcase)
  end

  def postcode=(value)
    super(PostcodeSanitizer.call(value))
  end

  def sanitized_name
    name.to_s.parameterize
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

  def subscribed?
    validated? && !unsubscribed?
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
    new_constituency_id = nil

    unless constituency_id?
      if united_kingdom? && postcode?
        new_constituency_id = constituency.try(:external_id)
      end
    end

    retry_lock do
      if pending?
        update_signature_counts = true
        petition.validate_creator! unless creator?

        attributes = {
          number:       petition.signature_count + 1,
          state:        VALIDATED_STATE,
          validated_at: now,
          updated_at:   now
        }

        if new_constituency_id
          attributes[:constituency_id] = new_constituency_id
        end

        unless signed_token?
          attributes[:signed_token] = Authlogic::Random.friendly_token
        end

        update_columns(attributes)
      end
    end

    if incremental_counting? && update_signature_counts
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

    if incremental_counting? && update_signature_counts
      ConstituencyPetitionJournal.invalidate_signature_for(self, now)
      CountryPetitionJournal.invalidate_signature_for(self, now)
      petition.decrement_signature_count!(now)
    end
  end

  def mark_seen_signed_confirmation_page!
    update seen_signed_confirmation_page: true
  end

  def save(*args)
    super
  rescue ActiveRecord::RecordNotUnique => e
    if creator?
      errors.add(:name, :already_signed, name: name, email: email) and return false
    else
      raise e
    end
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
    if constituency_id?
      @constituency ||= Constituency.find_by_external_id(constituency_id)
    elsif united_kingdom?
      @constituency ||= Constituency.find_by_postcode(postcode)
    end
  end

  def signed_token
    super || generate_and_save_signed_token
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

  def update_uuid
    update_column(:uuid, generate_uuid)
  end

  def email_threshold_reached?
    email_count >= 5
  end

  def united_kingdom?
    location_code == 'GB'
  end

  def update_all(updates)
    self.class.unscoped.where(id: id).update_all(updates)
  end

  private

  def incremental_counting?
    ENV['SERVER_TYPE'] == 'test'
  end

  def generate_uuid
    Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, "mailto:#{email}")
  end

  def generate_and_save_signed_token
    token = Authlogic::Random.friendly_token

    retry_lock do
      if signed_token?
        token = read_attribute(:signed_token)
      else
        update_column(:signed_token, token)
      end
    end

    token
  end

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
