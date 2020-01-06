class AddDissolvedMessageFieldsToParliament < ActiveRecord::Migration[4.2]
  def up
    add_column :parliaments, :dissolved_heading, :string, limit: 100
    add_column :parliaments, :dissolved_message, :text
  end
end
