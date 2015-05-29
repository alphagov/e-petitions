class SponsorMailer < ApplicationMailer
  def new_sponsor_email(sponsor)
    @sponsor = sponsor
    mail(subject: "Parliament petitions - #{@sponsor.petition.creator_signature.name} would like your support",
      to: @sponsor.email,
      cc: @sponsor.petition.creator_signature.email)
  end

  def sponsor_signed_email_below_threshold(petition, sponsor)
    @petition = petition
    @sponsor = sponsor
    @supporting_sponsors_count = petition.supporting_sponsors_count
    @moderation_threshold = AppConfig.sponsor_moderation_threshold
    mail(
      subject: "Parliament Petitions - #{@petition.title} has received support from a sponsor",
      to: @petition.creator_signature.email
    )
  end

  def sponsor_signed_email_on_threshold(petition, sponsor)
    @petition = petition
    @sponsor = sponsor
    @moderation_threshold = AppConfig.sponsor_moderation_threshold
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

