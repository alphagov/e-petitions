class PetitionSignedDataUpdateJob < ApplicationJob
  queue_as :highest_priority

  rescue_from(ActiveJob::DeserializationError) do |exception|
    Appsignal.send_exception exception
  end

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
      SponsorSignedEmailOnThresholdEmailJob.perform_later(petition, signature)
    elsif petition.collecting_sponsors?
      SponsorSignedEmailBelowThresholdEmailJob.perform_later(petition, signature)
    end
  end
end
