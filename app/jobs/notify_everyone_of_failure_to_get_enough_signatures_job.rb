class NotifyEveryoneOfFailureToGetEnoughSignaturesJob < ApplicationJob
  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  def perform(petition)
    creator = petition.creator
    sponsors = petition.sponsors.validated

    NotifyCreatorThatPetitionWasRejectedEmailJob.perform_later(creator, petition.rejection)

    sponsors.each do |sponsor|
      NotifySponsorThatPetitionWasRejectedEmailJob.perform_later(sponsor, petition.rejection)
    end
  end
end
