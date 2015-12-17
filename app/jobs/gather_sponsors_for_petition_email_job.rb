class GatherSponsorsForPetitionEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :gather_sponsors_for_petition
end
