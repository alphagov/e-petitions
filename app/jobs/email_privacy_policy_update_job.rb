class EmailPrivacyPolicyUpdateJob < ApplicationJob
  queue_as :low_priority

  def perform(petition:, time:)
    terminating = false

    worker = trap("TERM") do
      terminating = true
      worker.call
    end

    Appsignal.ignore_instrumentation_events do
      petition.signatures.validated.find_each do |signature|
        privacy_notification = PrivacyNotification.create!(
          id: signature.uuid,
          ignore_petitions_before: time
        )

        DeliverPrivacyPolicyUpdateJob.perform_later(privacy_notification)

        if terminating
          reschedule_job(petition: petition, time: time)
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

  def reschedule_job(petition:, time:)
    self
      .class
      .set(wait_until: 5.minutes.from_now)
      .perform_later(petition: petition, time: time)
  end
end
