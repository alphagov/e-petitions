class PetitionCountJob < ApplicationJob
  class InvalidSignatureCounts < RuntimeError; end

  delegate :update_signature_counts, to: :Site
  delegate :signature_count_interval, to: :Site
  delegate :disable_signature_counts!, to: :Site
  delegate :enable_signature_counts!, to: :Site
  delegate :disable_invalid_signature_count_check?, to: :Site

  queue_as :highest_priority

  def perform(now = Time.current)
    return if disable_invalid_signature_count_check?

    if update_signature_counts
      disable_signature_counts!
      reschedule_job(scheduled_time(now))
    else
      unless petitions.empty?
        petitions.each(&:reset_signature_count!)
        send_notification(petitions)
      end

      enable_signature_counts!
    end
  end

  private

  def petitions
    @petitions ||= fetch_petitions
  end

  def fetch_petitions
    petitions_scope.reject(&:valid_signature_count?)
  end

  def petitions_scope
    Petition.signed_since(36.hours.ago)
  end

  def reschedule_job(time)
    self.class.set(wait_until: time).perform_later
  end

  def scheduled_time(now)
    signature_count_interval.seconds.since(now) + 30.seconds
  end

  def send_notification(petitions)
    Appsignal.send_exception(exception(petitions))
  end

  def exception(petitions)
    InvalidSignatureCounts.new(error_message(petitions))
  end

  def error_message(petitions)
    I18n.t(
      :"invalid_signature_counts",
        scope:  :"petitions.errors",
        count:  petitions.size,
        ids:    petitions.map(&:id).inspect,
        id:     petitions.first.id.to_s
    )
  end
end
