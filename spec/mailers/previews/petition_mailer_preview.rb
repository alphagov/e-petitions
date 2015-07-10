# Preview all emails at http://localhost:3000/rails/mailers/petition_mailer
class PetitionMailerPreview < ActionMailer::Preview
  def email_confirmation_for_signer
    PetitionMailer.email_confirmation_for_signer(Signature.last)
  end
  def gather_sponsors_for_petition
    PetitionMailer.gather_sponsors_for_petition(Petition.last)
  end
end
