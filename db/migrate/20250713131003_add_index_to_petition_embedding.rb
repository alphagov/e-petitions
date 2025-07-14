class AddIndexToPetitionEmbedding < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    %i[petitions archived_petitions].each do |table|
      add_index table, :embedding, using: :hnsw, opclass: :halfvec_cosine_ops, algorithm: :concurrently, if_not_exists: true
    end
  end

  def down
    %i[petitions archived_petitions].each do |table|
      remove_index table, :embedding, algorithm: :concurrently, if_exists: true
    end
  end
end
