class ChangeForeignKeyToRestrictOnPetitionCreator < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key :petitions, column: :creator_signature_id
    add_foreign_key :petitions, :signatures, column: :creator_signature_id, on_delete: :restrict
  end

  def down
    remove_foreign_key :petitions, column: :creator_signature_id
    add_foreign_key :petitions, :signatures, column: :creator_signature_id, on_delete: :cascade
  end
end
