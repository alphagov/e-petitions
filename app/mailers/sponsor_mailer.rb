class SponsorMailer < ApplicationMailer
  def sponsor_signed_email_below_threshold(petition, sponsor)
    @petition = petition
    @sponsor = sponsor
    @supporting_sponsors_count = petition.supporting_sponsors_count
    @moderation_threshold = Site.threshold_for_moderation
    mail(
      subject: "#{@sponsor.signature.name} supported your petition",
      to: @petition.creator_signature.email
    )
  end

  def sponsor_signed_email_on_threshold(petition, sponsor)
    @petition = petition
    @sponsor = sponsor
    @moderation_threshold = Site.threshold_for_moderation
    mail(
      subject: "We’re checking your petition",
      to: @petition.creator_signature.email
    )
  end

  def petition_and_email_confirmation_for_sponsor(sponsor)
    @petition = sponsor.petition
    @signature = sponsor.signature
    mail(
      subject: "Please confirm your email address",
      to: @signature.email
    )
  end
end

