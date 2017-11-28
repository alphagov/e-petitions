class AddCanonicalEmailToSignatures < ActiveRecord::Migration[4.2]
  def up
    unless column_exists?(:signatures, :canonical_email)
      add_column :signatures, :canonical_email, :string
    end
  end

  def down
    if column_exists?(:signatures, :canonical_email)
      remove_column :signatures, :canonical_email
    end
  end
end
