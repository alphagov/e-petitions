class CreateRejections < ActiveRecord::Migration[4.2]
  def change
    create_table :rejections do |t|
      t.references :petition
      t.string :code, limit: 50, null: false
      t.text :details
      t.timestamps null: false
    end

    add_index :rejections, :petition_id, unique: true
    add_foreign_key :rejections, :petitions, on_delete: :cascade
  end
end
