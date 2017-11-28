class AddIndexOnGovernmentResponseUpdatedAt < ActiveRecord::Migration[4.2]
  def change
    add_index :government_responses, :updated_at
  end
end
