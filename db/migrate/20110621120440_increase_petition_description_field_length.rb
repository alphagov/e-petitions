class IncreasePetitionDescriptionFieldLength < ActiveRecord::Migration
  def self.up
    change_column :petitions, :description, :text
  end

  def self.down
    change_column :petitions, :description, :string
  end
end
