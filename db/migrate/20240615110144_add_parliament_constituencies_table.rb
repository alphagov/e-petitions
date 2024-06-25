class AddParliamentConstituenciesTable < ActiveRecord::Migration[7.1]
  def change
    create_table :parliament_constituencies do |t|
      t.bigint :parliament_id, null: false
      t.string :constituency_id, limit: 30, null: false
  
      t.timestamps
    end
  
    add_index :parliament_constituencies, [:parliament_id, :constituency_id], unique: true
    add_index :parliament_constituencies, :constituency_id
  
    add_foreign_key :parliament_constituencies, :parliaments
    add_foreign_key :parliament_constituencies, :constituencies, primary_key: :external_id
  end
end
