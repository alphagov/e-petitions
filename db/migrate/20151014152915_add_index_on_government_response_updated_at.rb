class AddIndexOnGovernmentResponseUpdatedAt < ActiveRecord::Migration
  def change
    add_index :government_responses, :updated_at
  end
end
