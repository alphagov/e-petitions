class CreateAdminSettings < ActiveRecord::Migration
  def change
    create_table :admin_settings do |t|
      t.string :petition_tags, null: false, default: ""

      t.timestamps null: false
    end
  end
end
