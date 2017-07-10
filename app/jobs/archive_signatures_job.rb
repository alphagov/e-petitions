class ArchiveSignaturesJob < ApplicationJob
  queue_as :low_priority

  def perform(petition, archived_petition)
    terminating = false

    worker = trap("TERM") do
      terminating = true
      worker.call
    end

    Appsignal.without_instrumentation do
      petition.signatures.unarchived.find_each do |signature|
        signature.transaction do
          archived_signature = archived_petition.signatures.build do |s|
            s.uuid = signature.uuid
            s.state = signature.state
            s.number = signature.number
            s.name = signature.name
            s.email = signature.email
            s.postcode = signature.postcode
            s.location_code = signature.location_code
            s.constituency_id = signature.constituency_id
            s.ip_address = signature.ip_address
            s.perishable_token = signature.perishable_token
            s.unsubscribe_token = signature.unsubscribe_token
            s.notify_by_email = signature.notify_by_email
            s.validated_at = signature.validated_at
            s.invalidation_id = signature.invalidation_id
            s.invalidated_at = signature.invalidated_at
            s.government_response_email_at = signature.government_response_email_at
            s.debate_scheduled_email_at = signature.debate_scheduled_email_at
            s.debate_outcome_email_at = signature.debate_outcome_email_at
            s.petition_email_at = signature.petition_email_at
            s.creator = signature.creator?
            s.sponsor = signature.sponsor?
            s.created_at = signature.created_at
            s.updated_at = signature.updated_at
          end

          archived_signature.save!(validate: false)
          signature.update_column(:archived_at, Time.current)
        end

        if terminating
          reschedule_job(petition, archived_petition)
          return true
        end
      end
    end

    petition.update_column(:archived_at, Time.current)

  ensure
    trap "TERM", worker
  end

  private

  def reschedule_job(petition, archived_petition, wait_until = 5.minutes.from_now)
    self.class.set(wait_until: wait_until).perform_later(petition, archived_petition)
  end
end
