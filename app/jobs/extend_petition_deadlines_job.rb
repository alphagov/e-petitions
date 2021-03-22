class ExtendPetitionDeadlinesJob < ApplicationJob
  queue_as :high_priority

  def perform
    if Site.signature_collection_disabled?
      open_petitions.find_each do |petition|
        petition.extend_deadline!
      end
    end
  end

  private

  def open_petitions
    Petition.open_state
  end
end
