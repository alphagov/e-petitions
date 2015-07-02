class PetitionMailer < ApplicationMailer
  include ActiveSupport::NumberHelper

  def email_confirmation_for_signer(signature)
    @signature = signature
    mail to: @signature.email, subject: subject_for(:email_confirmation_for_signer)
  end

  def special_resend_of_email_confirmation_for_signer(signature)
    @signature = signature
    mail to: @signature.email, subject: subject_for(:special_resend_of_email_confirmation_for_signer)
  end

  def notify_creator_that_petition_is_published(signature)
    @signature = signature
    mail to: @signature.email, subject: subject_for(:notify_creator_that_petition_is_published)
  end

  def petition_rejected(petition)
    @petition, @rejection = petition, petition.rejection
    to = @petition.creator_signature.email
    bcc = @petition.sponsor_signatures.validated.map(&:email)
    mail to: to, bcc: bcc, subject: subject_for(:petition_rejected)
  end

  def notify_signer_of_threshold_response(petition, signature)
    @petition, @signature = petition, signature
    mail to: @signature.email, subject: subject_for(:notify_signer_of_threshold_response)
  end

  def no_signature_for_petition(petition, email)
    @petition = petition
    mail to: email, subject: subject_for(:no_signature_for_petition)
  end

  def email_already_confirmed_for_signature(signature)
    @signature = signature
    mail to: @signature.email, subject: subject_for(:email_already_confirmed_for_signature)
  end

  def two_pending_signatures(signature_one, signature_two)
    @signature_one, @signature_two = signature_one, signature_two
    mail to: @signature_one.email, subject: subject_for(:two_pending_signatures)
  end

  def one_pending_one_validated_signature(pending_signature, validated_signature)
    @pending_signature, @validated_signature = pending_signature, validated_signature
    mail to: @pending_signature.email, subject: subject_for(:one_pending_one_validated_signature)
  end

  def double_signature_confirmation(*signatures)
    @signature_one, @signature_two = signatures.first, signatures.second
    mail to: @signature_one.email, subject: subject_for(:double_signature_confirmation)
  end

  def notify_creator_of_closing_date_change(signature)
    @signature = signature
    mail to: @signature.email, subject: subject_for(:notify_creator_of_closing_date_change)
  end

  def gather_sponsors_for_petition(petition)
    @petition, @creator = petition, petition.creator_signature
    mail to: @creator.email, subject: subject_for(:gather_sponsors_for_petition)
  end

  def notify_signer_of_debate_outcome(petition, signature)
    @petition = petition
    @signature = signature
    mail(
      subject: subject_for(:notify_signer_of_debate_outcome),
      to: @signature.email
    )
  end

  def notify_signer_of_debate_scheduled(petition, signature)
    @petition = petition
    @signature = signature
    mail(
      subject: subject_for(:notify_signer_of_debate_scheduled),
      to: @signature.email
    )
  end

  private

  def subject_for(key, options = {})
    I18n.t key, i18n_options.merge(options)
  end

  def i18n_options
    {}.tap do |options|
      options[:scope] = :"petitions.emails.subjects"

      if defined?(@petition)
        options[:count] = @petition.signature_count
        options[:formatted_count] = number_to_delimited(@petition.signature_count)
        options[:action] = @petition.action
      end
    end
  end
end
