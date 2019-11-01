class NotifyPetitionThatParliamentIsDissolvingJob < ApplicationJob
  queue_as :low_priority

  def perform(petition)
    Appsignal.without_instrumentation do
      signatures_to_email(petition).find_each do |signature|
        begin
          enqueue_notification(create_record(signature))
        rescue ActiveRecord::RecordNotUnique => e
          next
        end
      end
    end
  end

  private

  def signatures_to_email(petition)
    petition.signatures.validated.subscribed
  end

  def enqueue_notification(record)
    DeliverDissolutionNotificationJob.perform_later(record)
  end

  def create_record(signature)
    DissolutionNotification.create!(id: signature.uuid)
  end
end
