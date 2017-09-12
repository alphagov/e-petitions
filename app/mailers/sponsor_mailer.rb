class SponsorMailer < ApplicationMailer
  def sponsor_signed_email_below_threshold(petition, sponsor)
    @petition, @sponsor = petition, sponsor
    @sponsor_count = petition.sponsors.validated.count

    mail(
      subject: "#{@sponsor.name} supported your petition",
      to: @petition.creator.email
    )
  end

  def sponsor_signed_email_on_threshold(petition, sponsor)
    @petition, @sponsor = petition, sponsor
    @sponsor_count = petition.sponsors.validated.count

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

