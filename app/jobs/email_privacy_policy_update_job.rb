class EmailPrivacyPolicyUpdateJob < ApplicationJob
  queue_as :low_priority

  def perform(petition)
    terminating = false

    worker = trap("TERM") do
      terminating = true
      worker.call
    end

    Appsignal.without_instrumentation do
      petition.signatures.validated.find_each do |signature|
        privacy_notification = PrivacyNotification.create!(id: signature.uuid)
        DeliverPrivacyPolicyUpdateJob.perform_later(privacy_notification)

        if terminating
          reschedule_job(petition)
          return true
        end
      rescue ActiveRecord::RecordNotUnique
        next
      end
    end
  ensure
    trap("TERM", worker)
  end

  private

  def reschedule_job(petition)
    self.class.set(wait_until: 5.minutes.from_now).perform_later(petition)
  end
end
