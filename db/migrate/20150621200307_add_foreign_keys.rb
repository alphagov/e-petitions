class AddForeignKeys < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :constituency_petition_journals, :petitions, on_delete: :cascade
    add_foreign_key :debate_outcomes, :petitions, on_delete: :cascade
    add_foreign_key :petitions, :signatures, column: :creator_signature_id, on_delete: :cascade
    add_foreign_key :signatures, :petitions, on_delete: :cascade
    add_foreign_key :sponsors, :petitions, on_delete: :cascade
    add_foreign_key :sponsors, :signatures, on_delete: :cascade
  end
end
