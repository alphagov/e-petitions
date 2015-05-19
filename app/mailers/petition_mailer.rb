class PetitionMailer < ApplicationMailer
  include ActionView::Helpers::NumberHelper
  add_template_helper(DateTimeHelper)

  def email_confirmation_for_creator(signature)
    @signature = signature
    mail(:subject => "HM Government e-petitions: Email address confirmation", :to => @signature.email)
  end

  def email_confirmation_for_signer(signature)
    @signature = signature
    mail(:subject => "HM Government e-petitions: Email address confirmation", :to => @signature.email)
  end

  def special_resend_of_email_confirmation_for_signer(signature)
    @signature = signature
    mail(:subject => "HM Government e-petitions: Email address confirmation", :to => @signature.email)
  end

  def notify_creator_that_petition_is_published(signature)
    @signature = signature
    mail(:subject => "HM Government e-petitions: Your e-petition has been published", :to => @signature.email)
  end

  def notify_creator_that_petition_is_rejected(signature)
    @signature = signature
    mail(:subject => "HM Government e-petitions: Your e-petition has been rejected", :to => @signature.email)
  end

  def notify_signer_of_threshold_response(petition, signature)
    @petition = petition
    @signature = signature
    mail(:subject => "HM Government e-petitions: The petition '#{petition.title}' has reached #{number_with_delimiter(petition.signature_count)} signatures", :to => @signature.email)
  end

  def no_signature_for_petition(petition, email)
    @petition = petition
    mail  :subject => "HM Government e-petitions: a confirmation email has been requested",
          :to      => email
  end

  def email_already_confirmed_for_signature(signature)
    @signature = signature
    mail  :subject => "HM Government e-petitions: Signature already confirmed",
          :to      => @signature.email
  end

  def two_pending_signatures(signature_one, signature_two)
    @signature_one = signature_one
    @signature_two = signature_two
    mail  :subject => "HM Government e-petitions: Signature confirmations",
          :to      => @signature_one.email
  end

  def one_pending_one_validated_signature(pending_signature, validated_signature)
    @pending_signature   = pending_signature
    @validated_signature = validated_signature
    mail  :subject => "HM Government e-petitions: Signature confirmation",
          :to      =>  @pending_signature.email
  end

  def double_signature_confirmation(signatures)
    @signature_one = signatures.first
    @signature_two = signatures.second
    mail  :subject => "HM Government e-petitions: Signatures already confirmed",
          :to      => @signature_one.email
  end

  def notify_creator_of_closing_date_change(signature)
    @signature = signature
    mail :subject => "HM Government e-petitions: change to your e-petition closing date",
         :to      => @signature.email
  end

end
