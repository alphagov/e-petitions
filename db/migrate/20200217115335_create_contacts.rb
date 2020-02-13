class CreateContacts < ActiveRecord::Migration[5.2]
  def change
    create_table :contacts do |t|
      t.references :signature, null: false, unique: true, foreign_key: { on_delete: :cascade }
      t.string :address
      t.string :phone_number,  limit: 255
      t.timestamps
    end
  end
end
