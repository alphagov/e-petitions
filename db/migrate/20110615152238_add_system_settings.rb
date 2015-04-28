class AddSystemSettings < ActiveRecord::Migration
  def self.up
    create_table :system_settings, :force => true do |t|
      t.string   :key,         :limit => 64, :null => false
      t.text     :value
      t.text     :description
      t.timestamps
    end

    add_index :system_settings, [:key], :unique => true
  end

  def self.down
    drop_table :system_settings
  end
end
