class SponsorMailer < ApplicationMailer
  def new_sponsor_email(sponsor)
    @sponsor = sponsor
    mail(subject: "Parliament petitions - #{@sponsor.petition.creator_signature.name} would like your support",
      to: @sponsor.email,
      cc: @sponsor.petition.creator_signature.email)
  end
end

