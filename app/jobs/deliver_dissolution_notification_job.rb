class DeliverDissolutionNotificationJob < EmailJob
  queue_as :low_priority

  def perform(record)
    if Parliament.dissolution_at?
      send_signer_email(record) if record.signer?
      send_creator_email(record) if record.creator?

      record.touch
    end
  end

  private

  def mailer
    PetitionMailer
  end

  def signer_email(signature, petitions, remaining)
    mailer.notify_signer_of_closing_date_change(signature, petitions, remaining)
  end

  def send_signer_email(record)
    signer_email(record.signature, record.petitions, record.remaining_petitions).deliver_now
  end

  def creator_email(signature, petitions, remaining)
    mailer.notify_creator_of_closing_date_change(signature, petitions, remaining)
  end

  def send_creator_email(record)
    creator_email(record.signature, record.created_petitions, record.remaining_created_petitions).deliver_now
  end
end
