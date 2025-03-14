class CreateEmailTemplateAndPartialTables < ActiveRecord::Migration[7.2]
  def change
    create_table :email_partials do |t|
      t.string :name, limit: 50, null: false
      t.text   :content, limit: 10000, null: false
      t.timestamps

      t.index :name, unique: true
    end

    create_table :email_templates do |t|
      t.string  :mailer_name, limit: 50, null: false
      t.string  :action_name, limit: 50, null: false
      t.string  :subject, limit: 200, null: false
      t.text    :content, limit: 10000, null: false
      t.boolean :active, null: false, default: false
      t.timestamps

      t.index [:mailer_name, :action_name], unique: true
    end
  end
end
