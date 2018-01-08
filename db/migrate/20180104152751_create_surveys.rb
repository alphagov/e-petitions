class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.string :subject, null: false
      t.text :body
      t.integer :percentage_petitioners
      t.string :constituency_id
      t.timestamps null: false
    end

    add_index :surveys, :constituency_id

    create_table :petitions_surveys, id: false do |t|
      t.belongs_to :petition, index: true
      t.belongs_to :survey, index: true
    end
  end
end
