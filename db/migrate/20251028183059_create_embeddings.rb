class CreateEmbeddings < ActiveRecord::Migration[8.0]
  def change
    create_table :embeddings, id: :string do |t|
      t.halfvec :embedding, limit: 1024
      t.timestamps
    end
  end
end
