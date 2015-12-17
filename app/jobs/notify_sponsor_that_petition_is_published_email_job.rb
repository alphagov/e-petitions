class NotifySponsorThatPetitionIsPublishedEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :notify_sponsor_that_petition_is_published
end
