class CreateSponsors < ActiveRecord::Migration
  def change
    create_table :sponsors do |t|
      t.string :encrypted_email
      t.string :perishable_token
      t.integer :petition_id
      t.integer :signature_id

      t.timestamps null: false
    end
  end
end
