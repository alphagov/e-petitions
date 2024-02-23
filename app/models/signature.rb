require 'active_support/core_ext/digest/uuid'
require 'domain_autocorrect'
require 'postcode_sanitizer'
require 'ipaddr'
require 'mail'

class Signature < ActiveRecord::Base
  include PerishableTokenGenerator
  include GeoipLookup, Anonymize

  has_perishable_token
  has_perishable_token called: 'signed_token'
  has_perishable_token called: 'unsubscribe_token'

  ISO8601_TIMESTAMP = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/
  LOCATION_CODE = /\A[A-Z]{2,3}\z/

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
    'petition_email'      => :petition_email_at,
    'petition_mailshot'   => :petition_mailshot_at
  }

  belongs_to :petition
  belongs_to :invalidation, optional: true

  validates :state, inclusion: { in: STATES }
  validates :name, presence: true, length: { maximum: 255 }
  validates :name, format: { without: URI::regexp, message: :has_uri }
  validates :email, presence: true, email: { allow_blank: true }
  validates :location_code, presence: true, format: { with: LOCATION_CODE }
  validates :postcode, presence: true, postcode: true, if: :united_kingdom?
  validates :postcode, length: { maximum: 255 }, allow_blank: true
  validates :uk_citizenship, acceptance: true, unless: :persisted?, allow_nil: false
  validates :constituency_id, length: { maximum: 255 }

  validate do
    errors.add(:name, :invalid) if name.to_s =~ /\A[-=+@]/
  end

  attr_readonly :sponsor, :creator

  before_validation if: :autocorrect_domain do
    self.email = DomainAutocorrect.call(email)
  end

  before_create if: :email? do
    self.uuid = generate_uuid
    self.canonical_email = Domain.normalize(email)

    if find_duplicate
      raise ActiveRecord::RecordNotUnique, "Signature is not unique: #{name}, #{email}, #{postcode}"
    end

    if find_similar
      raise ActiveRecord::RecordNotUnique, "Signature is not unique: #{name}, #{email}, #{postcode}"
    end
  end

  after_create do
    Appsignal.increment_counter("signature.created", 1)
  end

  before_destroy do
    throw :abort if creator?
  end

  after_destroy do
    if validated?
      now = Time.current
      ConstituencyPetitionJournal.invalidate_signature_for(self, now)
      CountryPetitionJournal.invalidate_signature_for(self, now)
      petition.decrement_signature_count!(now)
    end

    Appsignal.increment_counter("signature.deleted", 1)
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
      where(id_not_eq(id).and(lower_email_eq(email)))
    end

    def duplicate_emails
      unscoped.from(validated.select(:uuid).group(:uuid).having(arel_table[Arel.star].count.gt(1))).count
    end

    def pending_rate
      (Rational(pending.count, total.count) * 100).to_d(2)
    end

    def subscribers
      validated.subscribed.count
    end

    def similar(id, email)
      where(canonical_email: email).where.not(id: id)
    end

    def for_domain(domain)
      where(domain_index.eq(domain[1..-1]))
    end

    def for_email(email)
      where(email_index.eq(normalize_email(email)))
    end

    def for_invalidating
      where(state: [PENDING_STATE, VALIDATED_STATE])
    end

    def for_ip(ip)
      where(ip_index, ip: ip)
    end

    def for_name(name)
      where(arel_table[:name].lower.eq(name.downcase))
    end

    def for_petition(id)
      where(petition_id: id)
    end

    def for_postcode(postcode)
      where(postcode: PostcodeSanitizer.call(postcode))
    end

    def for_sector(postcode)
      where("LEFT(postcode, -3) = ?", PostcodeSanitizer.call(postcode)[0..-4])
    end

    def for_timestamp(timestamp, since:)
      column = arel_table[column_name_for(timestamp)]
      where(column.eq(nil).or(column.lt(since)))
    end

    def fraudulent
      where(state: FRAUDULENT_STATE)
    end

    def fraudulent_domains
      where(state: FRAUDULENT_STATE).select(domain_index.as("domain")).group(domain_index).order(count_star.desc).count(:all)
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

    def need_emailing_for(timestamp, since:, scope: nil)
      validated.subscribed.where(scope).for_timestamp(timestamp, since: since)
    end

    def open_at_dissolution
      joins(:petition).merge(Petition.open_at_dissolution)
    end

    def pending
      where(state: PENDING_STATE)
    end

    def total
      where(state: [PENDING_STATE, VALIDATED_STATE])
    end

    def petition_ids_signed_since(timestamp)
      validated(since: timestamp).distinct.pluck(:petition_id)
    end

    def search(query, options = {})
      query  = query.to_s
      state  = options[:state]
      window = options[:window]
      page   = [options[:page].to_i, 1].max
      scope  = preload(:petition).by_most_recent

      if state.in?(STATES)
        scope = scope.where(state: state)
      end

      if window.present?
        if window =~ ISO8601_TIMESTAMP
          starts_at = window.in_time_zone.at_beginning_of_hour
          ends_at = starts_at.advance(hours: 1)
          scope = scope.where(created_at: starts_at..ends_at)
        elsif window =~ /\A\d+\z/
          starts_at = window.to_i.seconds.ago
          ends_at = Time.current
          scope = scope.where(created_at: starts_at..ends_at)
        end
      end

      if ip_search?(query)
        scope = scope.for_ip(query)
      elsif domain_search?(query)
        scope = scope.for_domain(query)
      elsif email_search?(query)
        scope = scope.for_email(query)
      elsif petition_search?(query)
        scope = scope.for_petition(query)
      elsif postcode_search?(query)
        scope = scope.for_postcode(query)
      elsif sector_search?(query)
        scope = scope.for_sector(query)
      elsif query.present?
        scope = scope.for_name(query)
      else
        scope = scope.none
      end

      scope.paginate(page: page, per_page: 50)
    end

    def creator
      where(arel_table[:creator].eq(true))
    end

    def not_creator
      where(arel_table[:creator].eq(false))
    end

    def sponsors
      where(arel_table[:sponsor].eq(true))
    end

    def subscribed
      where(notify_by_email: true)
    end

    def fraudulent_domains(since: 1.hour.ago, limit: 20)
      select(domain_index.as("domain")).
      where(arel_table[:created_at].gt(since)).
      where(state: FRAUDULENT_STATE).
      group(domain_index).
      order(count_star.desc).
      limit(limit).
      count(:all)
    end

    def fraudulent_ips(since: 1.hour.ago, limit: 20)
      select(:ip_address).
      where(arel_table[:created_at].gt(since)).
      where(state: FRAUDULENT_STATE).
      group(:ip_address).
      order(count_star.desc).
      limit(limit).
      count(:all)
    end

    def trending_domains(since: 1.hour.ago, limit: 20)
      select(domain_index.as("domain")).
      where(arel_table[:validated_at].gt(since)).
      where(arel_table[:invalidated_at].eq(nil)).
      group(domain_index).
      order(count_star.desc).
      limit(limit).
      count(:all)
    end

    def trending_ips(since: 1.hour.ago, limit: 20)
      select(:ip_address).
      where(arel_table[:validated_at].gt(since)).
      where(arel_table[:invalidated_at].eq(nil)).
      group(:ip_address).
      order(count_star.desc).
      limit(limit).
      count(:all)
    end

    def trending_domains_by_petition(window, threshold = 5)
      trending_domains = Hash.new { |h, k| h[k] = {} }

      where(validated_at: window)
        .group(:petition_id, domain_index)
        .having(count_star.gteq(threshold))
        .order(:petition_id, count_star.desc)
        .pluck(:petition_id, domain_index.as("domain"), count_star)
        .each_with_object(trending_domains) do |(petition_id, domain, count), hash|
          hash[petition_id][domain] = count
        end
    end

    def trending_ips_by_petition(window, threshold = 5, ignored_domains = [])
      trending_ips = Hash.new { |h, k| h[k] = {} }

      scope = where(validated_at: window)

      unless ignored_domains.empty?
        scope = scope.where(domain_index.not_in(ignored_domains))
      end

      scope
        .group(:petition_id, :ip_address)
        .having(count_star.gteq(threshold))
        .order(:petition_id, count_star.desc)
        .pluck(:petition_id, :ip_address, count_star)
        .each_with_object(trending_ips) do |(petition_id, ip_address, count), hash|
          hash[petition_id][ip_address] = count
        end
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

    def validate!(signature_ids, now = Time.current, force: false, request: nil)
      signatures = find(signature_ids)

      transaction do
        signatures.each do |signature|
          signature.validate!(now, force: force, request: request)
        end
      end
    end

    def validated(since: nil, upto: nil)
      scope = where(state: VALIDATED_STATE)
      scope = scope.where(validated_at.gt(since)) if since
      scope = scope.where(validated_at.lteq(upto)) if upto
      scope
    end

    def validated_count(timestamp, upto)
      validated(since: timestamp, upto: upto).pluck(count_star).first
    end

    def validated_count_by_location_code(timestamp, upto)
      validated(since: timestamp, upto: upto).group(:location_code).pluck(:location_code, count_star)
    end

    def validated_count_by_constituency_id(timestamp, upto)
      validated(since: timestamp, upto: upto).group(:constituency_id).pluck(:constituency_id, count_star)
    end

    def validated?(id)
      where(id: id).where(validated_at.not_eq(nil)).exists?
    end

    def earliest_validation
      validated.order(validated_at: :asc).limit(1).pluck(:validated_at).first
    end

    private

    def ip_search?(query)
      IPAddr.new(query)
    rescue IPAddr::InvalidAddressError => e
      false
    end

    def domain_search?(query)
      query.starts_with?('@')
    end

    def email_search?(query)
      query.include?('@')
    end

    def petition_search?(query)
      query =~ /\A\d+\z/
    end

    def postcode_search?(query)
      PostcodeSanitizer.call(query) =~ PostcodeValidator::PATTERN
    end

    def sector_search?(query)
      PostcodeSanitizer.call(query) =~ /\A[A-Z]{1,2}[0-9][0-9A-Z]?XXX\z/
    end

    def validated_at
      arel_table[:validated_at]
    end

    def domain_index
      Arel.sql("SUBSTRING(email FROM POSITION('@' IN email) + 1)")
    end

    def email_index
      Arel.sql("(REGEXP_REPLACE(LEFT(LOWER(email), POSITION('@' IN email) - 1), '\\.|\\+.+', '', 'g') || SUBSTRING(LOWER(email) FROM POSITION('@' IN email)))")
    end

    def ip_index
      Arel.sql("inet(ip_address) <<= inet(:ip)")
    end

    def count_star
      arel_table[Arel.star].count
    end

    def normalize_email(email)
      "#{normalize_user(email)}@#{normalize_domain(email)}"
    end

    def normalize_user(email)
      email.split("@").first.split("+").first.tr(".", "").downcase
    end

    def normalize_domain(email)
      email.split("@").last.downcase
    end

    def id_not_eq(id)
      arel_table[:id].not_eq(id)
    end

    def lower_email_eq(email)
      arel_table[:email].lower.eq(email.to_s.downcase)
    end
  end

  attr_accessor :uk_citizenship
  attr_reader :autocorrect_domain

  def autocorrect_domain=(value)
    @autocorrect_domain = value.present?
  end

  def find_duplicate
    begin
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
    rescue ActiveRecord::PreparedStatementCacheExpired => e
      retry
    end
  end

  def find_duplicate!
    find_duplicate || find_similar || (raise ActiveRecord::RecordNotFound, "Signature not found: #{name}, #{email}, #{postcode}")
  end

  def find_similar
    begin
      return nil unless petition

      signatures = petition.signatures.similar(id, canonical_email)
      return signatures.first if signatures.many?

      if signature = signatures.first
        if sanitized_name == signature.sanitized_name
          signature
        elsif postcode != signature.postcode
          signature
        end
      end
    rescue ActiveRecord::PreparedStatementCacheExpired => e
      retry
    end
  end

  def name=(value)
    super(value.to_s.strip)
  end

  def email=(value)
    super(normalize_email(value))
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
        Appsignal.increment_counter("signature.fraudulent", 1)
        update_columns(state: FRAUDULENT_STATE, updated_at: now)
      end
    end
  end

  def validate!(now = Time.current, force: false, request: nil)
    update_signature_counts = false
    new_constituency_id = nil

    unless constituency_id?
      if united_kingdom? && postcode?
        new_constituency_id = constituency.try(:external_id)
      end
    end

    retry_lock do
      if force || pending?
        update_signature_counts = true
        petition.validate_creator!(now) unless creator?

        attributes = {
          number:       petition.signature_count + 1,
          state:        VALIDATED_STATE,
          validated_at: now,
          invalidation_id: nil,
          invalidated_at:  nil,
          updated_at:   now
        }

        if request
          attributes[:validated_ip] = request.remote_ip
        end

        if new_constituency_id
          attributes[:constituency_id] = new_constituency_id
        end

        unless signed_token?
          attributes[:signed_token] = SecureRandom.base58(20)
        end

        update_columns(attributes)
      end
    end

    if update_signature_counts
      Appsignal.increment_counter("signature.validated", 1)
      @just_validated = true
    end

    if inline_updates? && update_signature_counts
      last_signed_at = petition.last_signed_at
      petition.increment_signature_count!(now)

      ConstituencyPetitionJournal.increment_signature_counts_for(petition, last_signed_at)
      CountryPetitionJournal.increment_signature_counts_for(petition, last_signed_at)
    end
  end

  def just_validated?
    defined?(@just_validated) ? @just_validated : false
  end

  def validated_before?(timestamp)
    validated? && validated_at < timestamp
  end

  def reload(*)
    super.tap { @just_validated = false }
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
      Appsignal.increment_counter("signature.invalidated", 1)
      ConstituencyPetitionJournal.invalidate_signature_for(self, now)
      CountryPetitionJournal.invalidate_signature_for(self, now)
      petition.decrement_signature_count!(now)
    end
  end

  def mark_seen_signed_confirmation_page!
    update seen_signed_confirmation_page: true
  end

  def save(**options)
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

  def account
    Mail::Address.new(email).local
  rescue Mail::Field::ParseError
    nil
  end

  def domain
    Mail::Address.new(email).domain
  rescue Mail::Field::ParseError
    nil
  end

  def rate(window = 5.minutes)
    time = created_at || Time.current
    period = Range.new(time - window, time)

    if creator?
      self.class.where(ip_address: ip_address, created_at: period, creator: true).count
    elsif sponsor?
      self.class.where(ip_address: ip_address, created_at: period, sponsor: true).count
    else
      petition.signatures.where(ip_address: ip_address, created_at: period).count
    end
  end

  def update_uuid
    update_column(:uuid, generate_uuid)
  end

  def update_canonical_email
    update_column(:canonical_email, Domain.normalize(email))
  end

  def number
    super || petition.signature_count + 1
  end

  def email_threshold_reached?
    email_count >= 5
  end

  def united_kingdom?
    location_code == 'GB'
  end
  alias_method :uk?, :united_kingdom?

  def update_all(updates)
    self.class.unscoped.where(id: id).update_all(updates)
  end

  def location
    if postcode?
      "#{formatted_postcode}, #{location_code}"
    else
      location_code
    end
  end

  def formatted_postcode
    if united_kingdom?
      postcode.gsub(/\A([A-Z0-9]+?)([A-Z0-9]{3})\z/, "\\1 \\2")
    else
      postcode
    end
  end

  private

  def normalize_email(value)
    return value unless value.present?

    Mail::Address.new(value.strip).yield_self do |address|
      "#{address.local}@#{address.domain.to_s.downcase}"
    end
  rescue Mail::Field::ParseError
    value
  end

  def inline_updates?
    ENV["INLINE_UPDATES"] == "true"
  end

  def generate_uuid
    Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, "mailto:#{email}")
  end

  def generate_and_save_signed_token
    token = SecureRandom.base58(20)

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
    rescue ActiveRecord::PreparedStatementCacheExpired => e
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
