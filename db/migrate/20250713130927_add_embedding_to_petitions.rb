class AddEmbeddingToPetitions < ActiveRecord::Migration[7.2]
  def change
    add_column :archived_petitions, :embedding, :halfvec, limit: 384
    add_column :petitions, :embedding, :halfvec, limit: 384
  end
end
