class AddSignatureCountValidatedAtToPetitions < ActiveRecord::Migration
  def up
    unless column_exists?(:petitions, :signature_count_validated_at)
      add_column :petitions, :signature_count_validated_at, :datetime
    end
  end

  def down
    if column_exists?(:petitions, :signature_count_validated_at)
      remove_column :petitions, :signature_count_validated_at
    end
  end
end
