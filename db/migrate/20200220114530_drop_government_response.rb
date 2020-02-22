class DropGovernmentResponse < ActiveRecord::Migration[5.2]
  def change
    revert do
      create_table :government_responses, id: :serial, force: :cascade do |t|
        t.integer :petition_id
        t.string :summary, limit: 500, null: false
        t.text :details
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false
        t.date :responded_on
        t.index [:petition_id], unique: true
        t.index [:updated_at]
      end

      add_column :petitions, :government_response_at, :datetime
      add_column :signatures, :government_response_email_at, :datetime
      add_column :email_requested_receipts, :government_response, :datetime

      add_foreign_key :government_responses, :petitions, on_delete: :cascade
    end
  end
end
