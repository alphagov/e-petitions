class CreatePages < ActiveRecord::Migration[7.2]
  def change
    create_table :pages do |t|
      t.string :slug, limit: 100, null: false
      t.string :title, limit: 100, null: false
      t.text :content, null: false
      t.timestamps
      t.index :slug, unique: true
    end
  end
end
