class ResetPetitionSignatureCountJob < ApplicationJob
  class InvalidSignatureCount < RuntimeError; end

  queue_as :highest_priority

  def perform(petition, time = current_time)
    petition.reset_signature_count!(time.in_time_zone)
    send_notification(petition)
  end

  private

  def current_time
    Time.current.change(usec: 0).iso8601
  end

  def send_notification(petition)
    Appsignal.send_exception(exception(petition))
  end

  def exception(petition)
    InvalidSignatureCount.new(error_message(petition))
  end

  def error_message(petition)
    I18n.t(:"invalid_signature_count", scope: :"petitions.errors", id: petition.id.to_s)
  end
end
