class RemoveIndexSignaturesOnPetitionIdAndStateAndName < ActiveRecord::Migration
  def change
    remove_index :signatures, [:petition_id, :state, :name]
  end
end
