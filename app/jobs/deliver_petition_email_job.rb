class DeliverPetitionEmailJob < ApplicationJob
  include EmailDelivery

  private

  def create_email(signature:, email:, **args)
    if signature.creator?
      EmailCreatorAboutOtherBusinessEmailJob.new(signature, email)
    else
      EmailSignerAboutOtherBusinessEmailJob.new(signature, email)
    end
  end
end
