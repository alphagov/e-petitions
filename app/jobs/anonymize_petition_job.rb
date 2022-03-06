class AnonymizePetitionJob < ApplicationJob
  queue_as :low_priority

  rescue_from ActiveRecord::RecordInvalid do |exception|
    Appsignal.send_exception exception
  end

  def perform(petition, time, limit: 500)
    time = time.in_time_zone
    terminating = false

    worker = trap("TERM") do
      terminating = true
      worker.call
    end

    Appsignal.without_instrumentation do
      if petition.signatures.not_anonymized.exists?
        signatures = petition.signatures.not_anonymized.take(limit)

        signatures.each do |signature|
          signature.anonymize!(time)

          if terminating
            reschedule_job(petition, time.iso8601, limit: limit)
            return true
          end
        end
      end
    end

    if petition.signatures.not_anonymized.exists?
      self.class.perform_later(petition, time.iso8601, limit: limit)
    else
      petition.update_column(:anonymized_at, time)
    end

  ensure
    trap "TERM", worker
  end

  private

  def reschedule_job(petition, time, limit: 500, wait_until: 5.minutes.from_now)
    self.class.set(wait_until: wait_until).perform_later(petition, time, limit: limit)
  end
end
