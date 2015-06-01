class AddSponsorTokenToPetitions < ActiveRecord::Migration
  def change
    add_column :petitions, :sponsor_token, :string, limit: 255
  end
end
