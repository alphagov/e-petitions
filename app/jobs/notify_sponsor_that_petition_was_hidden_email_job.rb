class NotifySponsorThatPetitionWasHiddenEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :notify_sponsor_that_petition_was_hidden
end
