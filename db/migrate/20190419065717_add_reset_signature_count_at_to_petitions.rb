class AddResetSignatureCountAtToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :signature_count_reset_at, :datetime
  end
end
