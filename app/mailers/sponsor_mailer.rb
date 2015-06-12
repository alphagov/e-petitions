class SponsorMailer < ApplicationMailer
  def sponsor_signed_email_below_threshold(petition, sponsor)
    @petition = petition
    @sponsor = sponsor
    @supporting_sponsors_count = petition.supporting_sponsors_count
    @moderation_threshold = Site.threshold_for_moderation
    mail(
      subject: "Parliament Petitions - #{@petition.title} has received support from a sponsor",
      to: @petition.creator_signature.email
    )
  end

  def sponsor_signed_email_on_threshold(petition, sponsor)
    @petition = petition
    @sponsor = sponsor
    @moderation_threshold = Site.threshold_for_moderation
    mail(
      subject: "Parliament Petitions - #{@petition.title} has received support from a sponsor",
      to: @petition.creator_signature.email
    )
  end

  def petition_and_email_confirmation_for_sponsor(sponsor)
    @petition = sponsor.petition
    @signature = sponsor.signature
    mail(
      subject: "Parliament petitions - Validate your support for #{@petition.creator_signature.name}'s petition #{@petition.title}",
      to: @signature.email
    )
  end
end

