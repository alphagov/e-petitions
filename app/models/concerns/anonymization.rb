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
      in_need_of_anonymizing(time).find_each do |petition|
        petition.anonymize!
      end
    end

    def in_need_of_anonymizing(time = Time.current)
      where(state: self::CLOSED_STATE, anonymized_at: nil).where(arel_table[:closed_at].lt(6.months.ago(time)))
    end
  end

  def anonymize!(time = Time.current)
    anonymization_job.perform_later(self, time.iso8601)
  end

  def anonymized?
    anonymized_at?
  end
end

