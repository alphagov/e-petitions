class SponsorMailer < ApplicationMailer
  include NumberHelper

  def sponsor_signed_email_below_threshold(sponsor)
    @petition, @sponsor = sponsor.petition, sponsor
    @sponsor_count = @petition.sponsor_count

    mail(
      subject: subject_for(:sponsor_signed_email_below_threshold),
      to: @petition.creator.email
    )
  end

  def sponsor_signed_email_on_threshold(sponsor)
    @petition, @sponsor = sponsor.petition, sponsor
    @sponsor_count = @petition.sponsor_count

    mail(
      subject: subject_for(:sponsor_signed_email_on_threshold),
      to: @petition.creator.email
    )
  end

  def petition_and_email_confirmation_for_sponsor(sponsor)
    @petition, @sponsor = sponsor.petition, sponsor

    mail(
      subject: subject_for(:petition_and_email_confirmation_for_sponsor),
      to: @sponsor.email
    )
  end

  private

  def subject_for(key, options = {})
    I18n.t key, **(i18n_options.merge(options))
  end

  def i18n_options
    {}.tap do |options|
      options[:scope] = :"petitions.emails.subjects"
      options[:threshold] = number_to_word(Site.threshold_for_moderation)

      if defined?(@sponsor)
        options[:name] = @sponsor.name
      end

      if defined?(@petition)
        options[:action] = @petition.action
      end
    end
  end
end
