class AddLastEmailledAtToSignatures < ActiveRecord::Migration
  def self.up
    add_column :signatures, :last_emailed_at, :datetime
  end

  def self.down
    remove_column :signatures, :last_emailed_at
  end
end
