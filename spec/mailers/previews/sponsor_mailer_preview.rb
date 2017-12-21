# Preview all emails at http://localhost:3000/rails/mailers/sponsor_mailer
class SponsorMailerPreview < ActionMailer::Preview
  def petition_and_email_confirmation_for_sponsor
    SponsorMailer.petition_and_email_confirmation_for_sponsor(Signature.sponsors.last)
  end

  def sponsor_signed_email_on_threshold
    sponsor = Signature.sponsors.last
    petition = sponsor.petition

    SponsorMailer.sponsor_signed_email_on_threshold(petition, sponsor)
  end
end
