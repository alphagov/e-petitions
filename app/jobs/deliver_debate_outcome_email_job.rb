class DeliverDebateOutcomeEmailJob < ApplicationJob
  include EmailDelivery

  private

  def create_email(signature:, petition:, **args)
    if petition.debated?
      create_positive_email(signature, petition.debate_outcome)
    else
      create_negative_email(signature, petition.debate_outcome)
    end
  end

  def create_positive_email(signature, outcome)
    if signature.creator?
      NotifyCreatorOfPositiveDebateOutcomeEmailJob.new(signature, outcome)
    else
      NotifySignerOfPositiveDebateOutcomeEmailJob.new(signature, outcome)
    end
  end

  def create_negative_email(signature, outcome)
    if signature.creator?
      NotifyCreatorOfNegativeDebateOutcomeEmailJob.new(signature, outcome)
    else
      NotifySignerOfNegativeDebateOutcomeEmailJob.new(signature, outcome)
    end
  end
end
