class ArchiveSignaturesJob < ApplicationJob
  queue_as :high_priority

  def perform(petition, archived_petition, id = 0, limit: 1000)
    signatures = petition.signatures.batch(id, limit: limit).to_a
    next_id = signatures.map(&:id).max + 1

    signatures.each do |signature|
      archived_petition.signatures.create! do |s|
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
    end

    if petition.signatures.batch(next_id, limit: limit).exists?
      self.class.perform_later(petition, archived_petition, next_id, limit: limit)
    else
      petition.touch(:archived_at)
    end
  end
end
