# Preview all emails at http://petitions.localhost:3000/rails/mailers/sponsor_mailer

class SponsorMailerPreview < ApplicationMailerPreview
  def petition_and_email_confirmation_for_sponsor
    SponsorMailer.petition_and_email_confirmation_for_sponsor(sponsor)
  end

  def sponsor_signed_email_below_threshold
    SponsorMailer.sponsor_signed_email_below_threshold(sponsor)
  end

  def sponsor_signed_email_on_threshold
    SponsorMailer.sponsor_signed_email_on_threshold(sponsor)
  end

  def sponsor_signed_email_on_threshold_with_delay
    SponsorMailer.sponsor_signed_email_on_threshold_with_delay(sponsor)
  end

  private

  def sponsor
    mock(:petition).sponsors.first
  end
end
