class UpdateSignatureCountsJob < ApplicationJob
  queue_as :highest_priority

  delegate :update_signature_counts, to: :Site
  delegate :signature_count_updated_at, to: :Site
  delegate :signature_count_interval, to: :Site
  delegate :signature_count_updated_at!, to: :Site
  delegate :petition_ids_signed_since, to: :Signature

  rescue_from StandardError do |exception|
    log_exception(exception)
    retry_job(wait: signature_count_interval)
  end

  def perform(now = current_time)
    # Exit if updating signature counts is disabled
    return unless update_signature_counts

    time = now.in_time_zone
    signature_count_at = signature_count_interval.seconds.ago(time)

    # Exit if the signature counts have been updated since this job was scheduled
    return unless signature_count_updated_at < signature_count_at

    petitions.each do |petition|
      # Skip this petition if it's been updated since this job was scheduled
      next if petition.last_signed_at? && petition.last_signed_at > signature_count_at

      # Check to see if the signature count is being reset
      if petition.signature_count_reset_at?
        if petition.signature_count_reset_at < 5.minutes.ago
          # Something's seriously wrong if a petition is taking
          # more than 5 minutes to reset its signature count
          message = "Petition #{petition.id} has been resetting its count for more than 5 minutes"
          Appsignal.send_exception(RuntimeError.new(message))
        end

        # Skip this petition as the updates will conflict
        next
      end

      # Save the current last_signed_at for the start of the journal window
      last_signed_at = petition.last_signed_at

      # Don't update the journals unless we have updated the signature count
      # This prevents the journals getting multiple updates before the creator's
      # signature is added to the count which may not be done immediately as the
      # main signature count window lags by `signature_count_interval` seconds
      # to prevent race conditions with validated_at timestamps created in Ruby
      if petition.increment_signature_count!(signature_count_at)
        ConstituencyPetitionJournal.increment_signature_counts_for(petition, last_signed_at)
        CountryPetitionJournal.increment_signature_counts_for(petition, last_signed_at)
      end
    end

    signature_count_updated_at!(signature_count_at)
    reschedule_job(scheduled_time(time))
  end

  private

  def current_time
    Time.current.change(usec: 0).iso8601
  end

  def log_exception(exception)
    logger.info(log_message(exception))
  end

  def log_message(exception)
    "#{exception.class.name} while running #{self.class.name}"
  end

  def petition_ids
    petition_ids_signed_since(signature_count_updated_at)
  end

  def petitions
    Petition.where(id: petition_ids)
  end

  def reschedule_job(time)
    self.class.set(wait_until: time).perform_later(time.iso8601)
  end

  def scheduled_time(now)
    signature_count_interval.seconds.since(now)
  end
end
