require_dependency 'archived'

module Archived
  class Signature < ActiveRecord::Base
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
    belongs_to :constituency, primary_key: :external_id

    validates :constituency_id, length: { maximum: 255 }
    validates :email, presence: true
    validates :location_code, presence: true
    validates :name, presence: true, length: { maximum: 255 }
    validates :state, presence: true, inclusion: { in: STATES }

    attr_readonly :sponsor, :creator

    class << self
      def batch(id = 0, limit: 1000)
        where(arel_table[:id].gteq(id)).order(id: :asc).limit(limit)
      end

      def column_name_for(timestamp)
        TIMESTAMPS.fetch(timestamp)
      rescue
        raise ArgumentError, "Unknown petition email timestamp: #{timestamp.inspect}"
      end

      def for_timestamp(timestamp, since:)
        column = arel_table[column_name_for(timestamp)]
        where(column.eq(nil).or(column.lt(since)))
      end

      def need_emailing_for(timestamp, since:)
        validated.subscribed.for_timestamp(timestamp, since: since)
      end

      def subscribed
        where(notify_by_email: true)
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

    private

    def column_name_for(timestamp)
      self.class.column_name_for(timestamp)
    end
  end
end
