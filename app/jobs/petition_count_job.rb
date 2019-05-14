class PetitionCountJob < ApplicationJob
  delegate :signature_count_interval, to: :Site
  delegate :disable_invalid_signature_count_check?, to: :Site

  queue_as :highest_priority

  def perform(now = current_time)
    return if disable_invalid_signature_count_check?

    unless petitions.empty?
      petitions.each do |petition|
        ResetPetitionSignatureCountJob.perform_later(petition, now)
      end
    end
  end

  private

  def current_time
    Time.current.change(usec: 0).iso8601
  end

  def signature_count_at(time)
    signature_count_interval.seconds.ago(time)
  end

  def petitions
    @petitions ||= fetch_petitions
  end

  def fetch_petitions
    petitions_scope.reject(&:valid_signature_count?)
  end

  def petitions_scope
    Petition.signed_since(36.hours.ago)
  end
end
