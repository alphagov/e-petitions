class DeliverPetitionEmailJob < ActiveJob::Base
  include EmailDelivery

  attr_reader :email

  def perform(**args)
    @email = args[:email]
    super
  end

  def create_email
    mailer.email_signer petition, signature, email
  end
end
