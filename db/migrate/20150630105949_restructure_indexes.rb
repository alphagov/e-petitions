class RestructureIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :signatures, [:petition_id, :state]
    remove_index :signatures, [:state]

    remove_index :petitions, [:state, :created_at]
    add_index :petitions, [:created_at, :state]

    remove_index :petitions, [:state, :signature_count]
    add_index :petitions, [:signature_count, :state]
  end
end
