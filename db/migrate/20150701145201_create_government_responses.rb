class CreateGovernmentResponses < ActiveRecord::Migration[4.2]
  def change
    create_table :government_responses do |t|
      t.references :petition
      t.string :summary, limit: 500, null: false
      t.text :details
      t.timestamps null: false
    end

    add_index :government_responses, :petition_id, unique: true
    add_foreign_key :government_responses, :petitions, on_delete: :cascade
  end
end
