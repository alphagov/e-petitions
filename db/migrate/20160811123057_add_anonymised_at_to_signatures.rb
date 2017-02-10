class AddAnonymisedAtToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :anonymised_at, :datetime
    add_index :signatures, [:anonymised_at, :petition_id]
  end
end
