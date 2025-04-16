# Preview all emails at http://petitions.localhost:3000/rails/mailers/petition_mailer

class PetitionMailerPreview < ApplicationMailerPreview
  def email_confirmation_for_signer
    PetitionMailer.email_confirmation_for_signer(signature)
  end

  def email_duplicate_signatures
    PetitionMailer.email_duplicate_signatures(signature)
  end

  def gather_sponsors_for_petition
    PetitionMailer.gather_sponsors_for_petition(petition)
  end

  def gather_sponsors_for_petition_with_delay
    PetitionMailer.gather_sponsors_for_petition_with_delay(petition)
  end

  def email_signer
    PetitionMailer.email_signer(petition, signature, email)
  end

  def email_creator
    PetitionMailer.email_creator(petition, creator, email)
  end

  def mailshot_for_signer
    PetitionMailer.mailshot_for_signer(petition, signature, mailshot)
  end

  def mailshot_for_creator
    PetitionMailer.mailshot_for_creator(petition, creator, mailshot)
  end

  def notify_creator_that_moderation_is_delayed
    subject = "Moderation of your petition has been delayed"
    body = "We are sorry, but moderation of your petition has been delayed due to an overwhelming number of requests."

    PetitionMailer.notify_creator_that_moderation_is_delayed(creator, subject, body)
  end

  def notify_signer_of_threshold_response
    PetitionMailer.notify_signer_of_threshold_response(petition, signature)
  end

  def notify_signer_of_debate_scheduled
    PetitionMailer.notify_signer_of_debate_scheduled(petition, signature)
  end

  def notify_creator_of_threshold_response
    PetitionMailer.notify_creator_of_threshold_response(petition, creator)
  end

  def notify_creator_of_debate_scheduled
    PetitionMailer.notify_creator_of_debate_scheduled(petition, creator)
  end

  def notify_creator_of_closing_date_change
    PetitionMailer.notify_creator_of_closing_date_change(creator, [petition], 5, parliament)
  end

  def notify_signer_of_closing_date_change
    PetitionMailer.notify_signer_of_closing_date_change(signature, [petition], 5, parliament)
  end

  def notify_creator_of_sponsored_petition_being_stopped
    PetitionMailer.notify_creator_of_sponsored_petition_being_stopped(creator, parliament)
  end

  def notify_creator_of_validated_petition_being_stopped
    PetitionMailer.notify_creator_of_validated_petition_being_stopped(creator, parliament)
  end

  def notify_signer_of_positive_debate_outcome
    PetitionMailer.notify_signer_of_positive_debate_outcome(petition, creator)
  end

  def notify_creator_of_positive_debate_outcome
    PetitionMailer.notify_creator_of_positive_debate_outcome(petition, creator)
  end

  def notify_signer_of_negative_debate_outcome
    PetitionMailer.notify_signer_of_negative_debate_outcome(not_debated_petition, not_debated_signature)
  end

  def notify_creator_of_negative_debate_outcome
    PetitionMailer.notify_creator_of_negative_debate_outcome(not_debated_petition, not_debated_creator)
  end

  def privacy_policy_update_email
    PetitionMailer.privacy_policy_update_email(privacy_notification)
  end

  def notify_creator_that_petition_is_published
    PetitionMailer.notify_creator_that_petition_is_published(creator)
  end

  def notify_creator_that_petition_was_rejected
    PetitionMailer.notify_creator_that_petition_was_rejected(rejected_creator)
  end

  def notify_creator_that_petition_was_hidden
    PetitionMailer.notify_creator_that_petition_was_hidden(hidden_creator)
  end

  def notify_sponsor_that_petition_is_published
    PetitionMailer.notify_sponsor_that_petition_is_published(sponsor)
  end

  def notify_sponsor_that_petition_was_rejected
    PetitionMailer.notify_sponsor_that_petition_was_rejected(rejected_sponsor)
  end

  def notify_sponsor_that_petition_was_hidden
    PetitionMailer.notify_sponsor_that_petition_was_hidden(hidden_sponsor)
  end

  private

  def petition
    mock(:petition)
  end

  def creator
    petition.creator
  end

  def sponsor
    petition.sponsors.last
  end

  def signature
    petition.signatures.last
  end

  def email
    petition.emails.first
  end

  def mailshot
    petition.mailshots.first
  end

  def rejected_petition
    mock(:rejected_petition)
  end

  def rejected_creator
    rejected_petition.creator
  end

  def rejected_sponsor
    rejected_petition.sponsors.last
  end

  def hidden_petition
    mock(:hidden_petition)
  end

  def hidden_creator
    hidden_petition.creator
  end

  def hidden_sponsor
    hidden_petition.sponsors.last
  end

  def not_debated_petition
    mock(:not_debated_petition)
  end

  def not_debated_creator
    not_debated_petition.creator
  end

  def not_debated_signature
    not_debated_petition.signatures.last
  end

  def parliament
    mock(:parliament)
  end

  def privacy_notification
    mock(:privacy_notification)
  end
end
