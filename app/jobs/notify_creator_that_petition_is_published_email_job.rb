class NotifyCreatorThatPetitionIsPublishedEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :notify_creator_that_petition_is_published
end
