class DropEmbeddingsTableIfExists < ActiveRecord::Migration[8.0]
  def change
    drop_table :embeddings, id: :string, if_exists: true do |t|
      t.halfvec :embedding, limit: 1024
      t.timestamps
    end
  end
end
