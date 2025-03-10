class NotifyEveryoneOfModerationDecisionJob < ApplicationJob
  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  def perform(petition)
    creator = petition.creator
    sponsors = petition.sponsors.validated

    if petition.published?
      notify_everyone_of_publication(creator, sponsors)
    elsif petition.hidden?
      notify_everyone_of_hidden_rejection(creator, sponsors)
    elsif petition.rejected?
      notify_everyone_of_public_rejection(creator, sponsors)
    end
  end

  private

  def notify_everyone_of_publication(creator, sponsors)
    NotifyCreatorThatPetitionIsPublishedEmailJob.perform_later(creator)

    sponsors.each do |sponsor|
      NotifySponsorThatPetitionIsPublishedEmailJob.perform_later(sponsor)
    end
  end

  def notify_everyone_of_hidden_rejection(creator, sponsors)
    NotifyCreatorThatPetitionWasHiddenEmailJob.perform_later(creator)

    sponsors.each do |sponsor|
      NotifySponsorThatPetitionWasHiddenEmailJob.perform_later(sponsor)
    end
  end

  def notify_everyone_of_public_rejection(creator, sponsors)
    NotifyCreatorThatPetitionWasRejectedEmailJob.perform_later(creator)

    sponsors.each do |sponsor|
      NotifySponsorThatPetitionWasRejectedEmailJob.perform_later(sponsor)
    end
  end
end
