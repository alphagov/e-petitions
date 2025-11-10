class SponsorMailer < ApplicationMailer
  include NumberHelper

  after_action do
    if @creator && @creator.anonymized?
      mail.perform_deliveries = false
    elsif @sponsor && @sponsor.anonymized?
      mail.perform_deliveries = false
    end
  end

  def sponsor_signed_email_below_threshold(sponsor)
    @petition, @creator = sponsor.petition, sponsor.petition.creator
    @sponsor_count = @petition.sponsor_count

    mail to: @creator.email,
      subject: subject_for(:sponsor_signed_email_below_threshold)
  end

  def sponsor_signed_email_on_threshold(sponsor)
    @petition, @creator = sponsor.petition, sponsor.petition.creator
    @sponsor_count = @petition.sponsor_count

    mail to: @creator.email,
      subject: subject_for(:sponsor_signed_email_on_threshold)
  end

  def sponsor_signed_email_on_threshold_with_delay(sponsor)
    @petition, @creator = sponsor.petition, sponsor.petition.creator
    @sponsor_count = @petition.sponsor_count

    mail to: @creator.email,
      subject: subject_for(:sponsor_signed_email_on_threshold_with_delay)
  end

  def petition_and_email_confirmation_for_sponsor(sponsor)
    @petition, @sponsor = sponsor.petition, sponsor

    mail to: @sponsor.email,
      subject: subject_for(:petition_and_email_confirmation_for_sponsor)
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
