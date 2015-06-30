class RestructureIndexes < ActiveRecord::Migration
  def change
    remove_index :signatures, [:petition_id, :state]
    remove_index :signatures, [:state]
  end
end
