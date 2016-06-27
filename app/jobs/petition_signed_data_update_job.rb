class PetitionSignedDataUpdateJob < ActiveJob::Base
  queue_as :highest_priority

  def perform(signature)
    ConstituencyPetitionJournal.record_new_signature_for(signature)
    CountryPetitionJournal.record_new_signature_for(signature)
    signature.petition.increment_signature_count!

    if signature.sponsor?
      send_sponsor_support_notification_email_to_petition_owner(signature)
    end
  end

  def send_sponsor_support_notification_email_to_petition_owner(signature)
    petition = signature.petition

    if petition.in_moderation?
      SponsorSignedEmailOnThresholdEmailJob.perform_later(petition, signature.sponsor)
    elsif petition.collecting_sponsors?
      SponsorSignedEmailBelowThresholdEmailJob.perform_later(petition, signature.sponsor)
    end
  end
end
