class UpdatePetitionEmbeddingJob < ApplicationJob
  retry_on Embedding::GenerationError, wait: :polynomially_longer, attempts: 10

  def perform(petition)
    petition.update_columns(embedding: Embedding.generate(petition.content))
  end
end
