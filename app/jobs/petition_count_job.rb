class PetitionCountJob < ApplicationJob
  delegate :signature_count_interval, to: :Site
  delegate :disable_invalid_signature_count_check?, to: :Site

  queue_as :highest_priority

  def perform(now = current_time)
    return if disable_invalid_signature_count_check?

    petitions.find_each do |petition|
      unless petition.valid_signature_count!
        ResetPetitionSignatureCountJob.perform_later(petition, now)
      end
    end
  end

  private

  def current_time
    Time.current.change(usec: 0).iso8601
  end

  def petitions
    Petition.in_need_of_validating
  end
end
