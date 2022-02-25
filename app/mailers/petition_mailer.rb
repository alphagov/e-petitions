class PetitionMailer < ApplicationMailer
  include ActiveSupport::NumberHelper

  after_action do
    if @signature && @signature.anonymized?
      mail.perform_deliveries = false
    end
  end

  def email_confirmation_for_signer(signature)
    @signature, @petition = signature, signature.petition
    mail to: @signature.email, subject: subject_for(:email_confirmation_for_signer)
  end

  def email_duplicate_signatures(signature)
    @signature, @petition = signature, signature.petition
    mail to: @signature.email, subject: subject_for(:email_duplicate_signatures)
  end

  def email_signer(petition, signature, email)
    @petition, @signature, @email = petition, signature, email

    mail to: @signature.email,
      subject: subject_for(:email_signer),
      list_unsubscribe: unsubscribe_url
  end

  def email_creator(petition, signature, email)
    @petition, @signature, @email = petition, signature, email

    mail to: @signature.email,
      subject: subject_for(:email_creator),
      list_unsubscribe: unsubscribe_url
  end

  def mailshot_for_signer(petition, signature, mailshot)
    @petition, @signature, @mailshot = petition, signature, mailshot

    mail to: @signature.email,
      subject: subject_for(:mailshot_for_signer),
      list_unsubscribe: unsubscribe_url
  end

  def mailshot_for_creator(petition, signature, mailshot)
    @petition, @signature, @mailshot = petition, signature, mailshot

    mail to: @signature.email,
      subject: subject_for(:mailshot_for_creator),
      list_unsubscribe: unsubscribe_url
  end

  def special_resend_of_email_confirmation_for_signer(signature)
    @signature, @petition = signature, signature.petition
    mail to: @signature.email, subject: subject_for(:special_resend_of_email_confirmation_for_signer)
  end

  def notify_creator_that_petition_is_published(signature)
    @signature, @petition = signature, signature.petition

    mail to: @signature.email,
      subject: subject_for(:notify_creator_that_petition_is_published),
      list_unsubscribe: unsubscribe_url
  end

  def notify_sponsor_that_petition_is_published(signature)
    @signature, @petition = signature, signature.petition
    mail to: @signature.email, subject: subject_for(:notify_sponsor_that_petition_is_published)
  end

  def notify_creator_that_petition_was_rejected(signature)
    @signature, @petition, @rejection = signature, signature.petition, signature.petition.rejection
    mail to: @signature.email, subject: subject_for(:notify_creator_that_petition_was_rejected)
  end

  def notify_sponsor_that_petition_was_rejected(signature)
    @signature, @petition, @rejection = signature, signature.petition, signature.petition.rejection
    mail to: @signature.email, subject: subject_for(:notify_sponsor_that_petition_was_rejected)
  end

  def notify_signer_of_threshold_response(petition, signature)
    @petition, @signature, @government_response = petition, signature, petition.government_response

    mail to: @signature.email,
      subject: subject_for(:notify_signer_of_threshold_response),
      list_unsubscribe: unsubscribe_url
  end

  def notify_creator_of_threshold_response(petition, signature)
    @petition, @signature, @government_response = petition, signature, petition.government_response

    mail to: @signature.email,
      subject: subject_for(:notify_creator_of_threshold_response),
      list_unsubscribe: unsubscribe_url
  end

  def notify_creator_of_closing_date_change(signature, petitions, remaining = 0)
    @signature, @petitions = signature, petitions
    @count, @remaining = @petitions.size, remaining

    @closing_time = Parliament.dissolution_at.strftime('%H:%M%P')
    @closing_date = Parliament.dissolution_at.strftime('%-d %B')
    @last_response_date = Parliament.dissolution_at.yesterday.strftime('%-d %B')
    @registration_deadline = Parliament.registration_closed_at.strftime('%A %-d %B')
    @election_date = Parliament.election_date.strftime('%-d %B')

    mail to: @signature.email, subject: subject_for(:notify_creator_of_closing_date_change, count: @count)
  end

  def notify_signer_of_closing_date_change(signature, petitions, remaining = 0)
    @signature, @petitions = signature, petitions
    @count, @remaining = @petitions.size, remaining

    @closing_time = Parliament.dissolution_at.strftime('%H:%M%P')
    @closing_date = Parliament.dissolution_at.strftime('%-d %B')
    @last_response_date = Parliament.dissolution_at.yesterday.strftime('%-d %B')
    @registration_deadline = Parliament.registration_closed_at.strftime('%A %-d %B')
    @election_date = Parliament.election_date.strftime('%-d %B')

    mail to: @signature.email, subject: subject_for(:notify_signer_of_closing_date_change, count: @count)
  end

  def notify_creator_of_sponsored_petition_being_stopped(signature)
    @signature, @petition = signature, signature.petition
    mail to: @signature.email, subject: subject_for(:notify_creator_of_sponsored_petition_being_stopped)
  end

  def notify_creator_of_validated_petition_being_stopped(signature)
    @signature, @petition = signature, signature.petition
    mail to: @signature.email, subject: subject_for(:notify_creator_of_validated_petition_being_stopped)
  end

  def gather_sponsors_for_petition(petition, bcc = nil)
    @petition, @creator = petition, petition.creator
    mail to: @creator.email, bcc: bcc, subject: subject_for(:gather_sponsors_for_petition)
  end

  def notify_signer_of_debate_outcome(petition, signature)
    @petition, @debate_outcome, @signature = petition, petition.debate_outcome, signature

    if @debate_outcome.debated?
      subject = subject_for(:notify_signer_of_positive_debate_outcome)
    else
      subject = subject_for(:notify_signer_of_negative_debate_outcome)
    end

    mail to: @signature.email, subject: subject, list_unsubscribe: unsubscribe_url
  end

  def notify_creator_of_debate_outcome(petition, signature)
    @petition, @debate_outcome, @signature = petition, petition.debate_outcome, signature

    if @debate_outcome.debated?
      subject = subject_for(:notify_creator_of_positive_debate_outcome)
    else
      subject = subject_for(:notify_creator_of_negative_debate_outcome)
    end

    mail to: @signature.email, subject: subject, list_unsubscribe: unsubscribe_url
  end

  def notify_signer_of_debate_scheduled(petition, signature)
    @petition, @signature = petition, signature

    mail to: @signature.email,
      subject: subject_for(:notify_signer_of_debate_scheduled),
      list_unsubscribe: unsubscribe_url
  end

  def notify_creator_of_debate_scheduled(petition, signature)
    @petition, @signature = petition, signature
    mail to: @signature.email,
      subject: subject_for(:notify_creator_of_debate_scheduled),
      list_unsubscribe: unsubscribe_url
  end

  def notify_creator_that_moderation_is_delayed(signature, subject, body)
    @petition, @signature = signature.petition, signature
    @subject, @body = subject, body

    mail to: @signature.email,
      subject: subject_for(:notify_creator_that_moderation_is_delayed),
      list_unsubscribe: unsubscribe_url
  end

  def privacy_policy_update_email(privacy_notification)
    @name = privacy_notification.name
    @petitions = privacy_notification.petitions
    @remaining_petition_count = privacy_notification.remaining_petition_count

    mail(
      to: privacy_notification.email,
      subject: subject_for(:privacy_policy_update_email)
    )
  end

  private

  def subject_for(key, options = {})
    I18n.t key, i18n_options.merge(options)
  end

  def signature_belongs_to_creator?
    @signature && @signature.creator?
  end

  def i18n_options
    {}.tap do |options|
      options[:scope] = :"petitions.emails.subjects"

      if defined?(@petition)
        options[:count] = @petition.signature_count
        options[:formatted_count] = number_to_delimited(@petition.signature_count)
        options[:action] = @petition.action
      end

      if defined?(@email)
        options[:subject] = @email.subject
      end

      if defined?(@mailshot)
        options[:subject] = @mailshot.subject
      end

      if defined?(@subject)
        options[:subject] = @subject
      end
    end
  end

  def unsubscribe_url
    "<#{unsubscribe_signature_url(@signature, token: @signature.unsubscribe_token)}>"
  end
end
