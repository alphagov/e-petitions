class SponsorMailer < ApplicationMailer
  def sponsor_signed_email_below_threshold(sponsor)
    @petition, @sponsor = sponsor.petition, sponsor
    @sponsor_count = @petition.sponsor_count

    mail(
      subject: "#{@sponsor.name} supported your petition",
      to: @petition.creator.email
    )
  end

  def sponsor_signed_email_on_threshold(sponsor)
    @petition, @sponsor = sponsor.petition, sponsor
    @sponsor_count = @petition.sponsor_count

    mail(
      subject: "We’re checking your petition",
      to: @petition.creator.email
    )
  end

  def petition_and_email_confirmation_for_sponsor(sponsor)
    @petition, @sponsor = sponsor.petition, sponsor

    mail(
      subject: "Please confirm your email address",
      to: @sponsor.email
    )
  end
end

