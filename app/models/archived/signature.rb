require 'ipaddr'

module Archived
  class Signature < ActiveRecord::Base
    include GeoipLookup, Anonymize

    ISO8601_TIMESTAMP = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/

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
    belongs_to :constituency, primary_key: :external_id, optional: true

    validates :constituency_id, length: { maximum: 255 }
    validates :email, presence: true
    validates :location_code, presence: true
    validates :name, presence: true, length: { maximum: 255 }
    validates :state, presence: true, inclusion: { in: STATES }

    attr_readonly :sponsor, :creator

    before_destroy do
      throw :abort if creator?
    end

    class << self
      def batch(id = 0, limit: 1000)
        where(arel_table[:id].gteq(id)).order(id: :asc).limit(limit)
      end

      def by_most_recent
        order(created_at: :desc)
      end

      def column_name_for(timestamp)
        TIMESTAMPS.fetch(timestamp)
      rescue
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

      def for_domain(domain)
        where(domain_index.eq(domain[1..-1]))
      end

      def for_email(email)
        where(email_index.eq(normalize_email(email)))
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

      def need_emailing_for(timestamp, since:, scope: nil)
        validated.subscribed.where(scope).for_timestamp(timestamp, since: since)
      end

      def subscribed
        where(notify_by_email: true)
      end

      def subscribers
        validated.subscribed.count
      end

      def validated
        where(state: VALIDATED_STATE)
      end

      def creator
        where(arel_table[:creator].eq(true))
      end

      def sponsors
        where(arel_table[:sponsor].eq(true))
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

        if window && window =~ ISO8601_TIMESTAMP
          starts_at = window.in_time_zone.at_beginning_of_hour
          ends_at = starts_at.advance(hours: 1)
          scope = scope.where(created_at: starts_at..ends_at)
        elsif window =~ /\A\d+\z/
          starts_at = window.to_i.seconds.ago
          ends_at = Time.current
          scope = scope.where(created_at: starts_at..ends_at)
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
              raise RuntimeError, "Can’t unsubscribe the creator signature"
            elsif signature.pending?
              raise RuntimeError, "Can’t unsubscribe a pending signature"
            else
              signature.update!(notify_by_email: false)
            end
          end
        end
      end

      private

      def domain_index
        Arel.sql("SUBSTRING(email FROM POSITION('@' IN email) + 1)")
      end

      def email_index
        Arel.sql("(REGEXP_REPLACE(LEFT(LOWER(email), POSITION('@' IN email) - 1), '\\.|\\+.+', '', 'g') || SUBSTRING(LOWER(email) FROM POSITION('@' IN email)))")
      end

      def ip_index
        Arel.sql("inet(ip_address) <<= inet((:ip)::text)")
      end

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

      def normalize_email(email)
        "#{normalize_user(email)}@#{normalize_domain(email)}"
      end

      def normalize_user(email)
        email.split("@").first.split("+").first.tr(".", "").downcase
      end

      def normalize_domain(email)
        email.split("@").last.downcase
      end
    end

    def get_email_sent_at_for(timestamp)
      self[column_name_for(timestamp)]
    end

    def set_email_sent_at_for(timestamp, to: Time.current)
      update_column(column_name_for(timestamp), to)
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

    def united_kingdom?
      location_code == 'GB'
    end
    alias_method :uk?, :united_kingdom?

    def location
      if postcode?
        "#{formatted_postcode}, #{location_code}"
      else
        location_code
      end
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

    private

    def formatted_postcode
      if united_kingdom?
        postcode.gsub(/\A([A-Z0-9]+?)([A-Z0-9]{3})\z/, "\\1 \\2")
      else
        postcode
      end
    end

    def column_name_for(timestamp)
      self.class.column_name_for(timestamp)
    end
  end
end
