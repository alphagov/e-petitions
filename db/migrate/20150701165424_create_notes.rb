class CreateNotes < ActiveRecord::Migration[4.2]
  def change
    create_table :notes do |t|
      t.references :petition
      t.text :details
      t.timestamps null: false
    end

    add_index :notes, :petition_id, unique: true
    add_foreign_key :notes, :petitions, on_delete: :cascade
  end
end
