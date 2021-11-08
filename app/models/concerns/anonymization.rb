module Anonymization
  extend ActiveSupport::Concern

  included do
    class_attribute :anonymization_job, instance_writer: false

    if self == Archived::Petition
      self.anonymization_job = Archived::AnonymizePetitionJob
    else
      self.anonymization_job = AnonymizePetitionJob
    end
  end

  module ClassMethods
    def anonymize_petitions!(time = Time.current)
      in_need_of_anonymizing(6.months.ago(time)).find_each do |petition|
        petition.anonymize!
      end
    end

    def in_need_of_anonymizing(time = 6.months.ago)
      not_anonymized.and(closed_before(time).or(rejected_before(time)))
    end

    def not_anonymized
      where(anonymized_at: nil)
    end

    def closed_before(time)
      where(state: self::CLOSED_STATE).where(arel_table[:closed_at].lt(time))
    end

    def rejected_before(time)
      where(state: self::REJECTED_STATES).where(arel_table[:rejected_at].lt(time))
    end
  end

  def anonymize!(time = Time.current)
    anonymization_job.perform_later(self, time.iso8601)
  end

  def anonymized?
    anonymized_at?
  end
end

