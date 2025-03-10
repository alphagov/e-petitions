class NotifyCreatorThatPetitionWasHiddenEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :notify_creator_that_petition_was_hidden
end
