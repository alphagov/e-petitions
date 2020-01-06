class AddRespondedOnToGovernmentResponses < ActiveRecord::Migration[4.2]
  def change
    change_table :archived_government_responses do |t|
      t.date :responded_on
    end

    change_table :government_responses do |t|
      t.date :responded_on
    end
  end
end
