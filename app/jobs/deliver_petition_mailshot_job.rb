class DeliverPetitionMailshotJob < ApplicationJob
  include EmailDelivery

  attr_reader :mailshot

  def perform(args)
    @mailshot = args[:mailshot]
    super
  end

  def create_email
    if signature.creator?
      mailer.mailshot_for_creator petition, signature, mailshot
    else
      mailer.mailshot_for_signer petition, signature, mailshot
    end
  end
end
