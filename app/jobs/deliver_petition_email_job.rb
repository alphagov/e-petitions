class DeliverPetitionEmailJob < ActiveJob::Base
  include EmailDelivery
  queue_as :deliver_petition_email

  attr_reader :email

  def perform(**args)
    @email = args[:email]
    super
  end

  def create_email
    mailer.email_signer petition, signature, email
  end
end
