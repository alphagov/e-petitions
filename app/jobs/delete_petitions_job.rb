class DeletePetitionsJob < ApplicationJob
  queue_as :high_priority

  def perform
    unless Petition.archived?
      raise RuntimeError, "Deleting petitions before they are archived will result in a loss of data"
    end

    Petition.find_each do |petition|
      DeletePetitionJob.perform_later(petition)
    end
  end
end
