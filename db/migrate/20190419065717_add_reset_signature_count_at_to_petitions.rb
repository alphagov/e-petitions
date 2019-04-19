class AddResetSignatureCountAtToPetitions < ActiveRecord::Migration
  def change
    add_column :petitions, :signature_count_reset_at, :datetime
  end
end
