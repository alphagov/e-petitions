# Preview all emails at http://localhost:3000/rails/mailers/petition_mailer
class PetitionMailerPreview < ActionMailer::Preview
  def email_confirmation_for_signer
    PetitionMailer.email_confirmation_for_signer(Signature.last)
  end
  def gather_sponsors_for_petition
    PetitionMailer.gather_sponsors_for_petition(Petition.last)
  end
  def notify_signer_of_threshold_response
    petition = Petition.with_response.last
    signature = petition.signatures.validated.last

    PetitionMailer.notify_signer_of_threshold_response(petition, signature)
  end
end
