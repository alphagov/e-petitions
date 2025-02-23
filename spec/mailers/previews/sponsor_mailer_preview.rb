# Preview all emails at http://petitions.localhost:3000/rails/mailers/sponsor_mailer
class SponsorMailerPreview < ActionMailer::Preview
  def petition_and_email_confirmation_for_sponsor
    petition = Petition.validated_state.last
    sponsor = petition.sponsors.last

    SponsorMailer.petition_and_email_confirmation_for_sponsor(sponsor)
  end

  def sponsor_signed_email_below_threshold
    petition = Petition.validated_state.last
    sponsor = petition.sponsors.last

    SponsorMailer.sponsor_signed_email_below_threshold(sponsor)
  end

  def sponsor_signed_email_on_threshold
    petition = Petition.sponsored_state.last
    sponsor = petition.sponsors.last

    SponsorMailer.sponsor_signed_email_on_threshold(sponsor)
  end
end
