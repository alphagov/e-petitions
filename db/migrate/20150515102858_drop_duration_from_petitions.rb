class DropDurationFromPetitions < ActiveRecord::Migration
  def change
    remove_column :petitions, :duration, :string, limit: 2, default: "12"
  end
end
