class ChangeNullabilityOnPetitionSignature < ActiveRecord::Migration
  def self.up
    change_column :petitions, :creator_signature_id, :integer, :null => false
    change_column :signatures, :petition_id, :integer, :null => true
  end

  def self.down
    change_column :petitions, :creator_signature_id, :integer, :null => true
    change_column :signatures, :petition_id, :integer, :null => false
  end
end
