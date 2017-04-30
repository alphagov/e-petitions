class NotifyCreatorOfValidatedPetitionBeingStoppedJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :notify_creator_of_validated_petition_being_stopped

  queue_as :low_priority

  def perform(signature)
    if Parliament.dissolved?
      mailer.send(email, signature).deliver_now
    end
  end
end

