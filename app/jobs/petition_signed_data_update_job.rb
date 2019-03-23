class PetitionSignedDataUpdateJob < ApplicationJob
  queue_as :highest_priority

  rescue_from(ActiveJob::DeserializationError) do |exception|
    Appsignal.send_exception exception
  end

  def perform(signature)
    ConstituencyPetitionJournal.record_new_signature_for(signature)
    CountryPetitionJournal.record_new_signature_for(signature)
    signature.petition.increment_signature_count!
  end
end
