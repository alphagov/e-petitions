module Archived
  class DeliverPetitionEmailJob < ApplicationJob
    include EmailDelivery

    attr_reader :email

    def perform(args)
      @email = args[:email]
      super
    end

    def create_email
      if signature.creator?
        mailer.email_creator petition, signature, email
      else
        mailer.email_signer petition, signature, email
      end
    end
  end
end
