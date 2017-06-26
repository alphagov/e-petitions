class AddLastPetitionCreatedAtToSite < ActiveRecord::Migration[4.2]
  def change
    add_column :sites, :last_petition_created_at, :datetime
  end
end
