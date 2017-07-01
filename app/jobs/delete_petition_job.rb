class DeletePetitionJob < ApplicationJob
  queue_as :high_priority

  def perform(petition)
    petition.destroy
  end
end
