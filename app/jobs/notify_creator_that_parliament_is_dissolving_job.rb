class NotifyCreatorThatParliamentIsDissolvingJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :notify_creator_of_closing_date_change

  queue_as :low_priority

  def perform(signature)
    if Parliament.dissolution_announced?
      mailer.send(email, signature).deliver_now
    end
  end
end
