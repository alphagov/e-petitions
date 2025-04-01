class GatherSponsorsForPetitionEmailJob < EmailJob
  self.mailer = PetitionMailer

  def email
    if Site.moderation_delay?
      :gather_sponsors_for_petition_with_delay
    else
      :gather_sponsors_for_petition
    end
  end
end
