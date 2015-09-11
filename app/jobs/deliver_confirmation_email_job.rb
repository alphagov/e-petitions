class DeliverConfirmationEmailJob < ActiveJob::Base
  #
  # Define a custom job class to deliver validation emails rather than use
  # PetitionMailer.x.perform_later so it uses a custom queue that is defined in 1 place
  # and not everywhere the PetitionMailer is used
  #

  queue_as :deliver_confirmation_email

  def perform(signature)
    PetitionMailer.email_confirmation_for_signer(signature).deliver_now
  end
end
