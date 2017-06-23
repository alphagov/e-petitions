class DropSystemSettings < ActiveRecord::Migration[4.2]
  def change
    drop_table :system_settings do |t|
      t.string   :key, limit: 64, null: false
      t.text     :value
      t.text     :description
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
