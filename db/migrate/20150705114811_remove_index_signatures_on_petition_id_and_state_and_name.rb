class RemoveIndexSignaturesOnPetitionIdAndStateAndName < ActiveRecord::Migration[4.2]
  def change
    remove_index :signatures, [:petition_id, :state, :name]
  end
end
