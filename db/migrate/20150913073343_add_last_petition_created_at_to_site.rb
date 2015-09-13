class AddLastPetitionCreatedAtToSite < ActiveRecord::Migration
  def change
    add_column :sites, :last_petition_created_at, :datetime
  end
end
