class BackfillPetitionEmbeddingsJob < ApplicationJob
  queue_as :low_priority

  def perform(force: false, clear_cache: false)
    Rails.cache.clear if clear_cache

    petitions(force).find_each do |petition|
      UpdatePetitionEmbeddingJob.perform_later(petition)
    end

    archived_petitions(force).find_each do |petition|
      UpdatePetitionEmbeddingJob.perform_later(petition)
    end
  end

  private

  def petitions(force)
    force ? Petition.all : Petition.where(embedding: nil)
  end

  def archived_petitions(force)
    force ? Archived::Petition.all : Archived::Petition.where(embedding: nil)
  end
end
