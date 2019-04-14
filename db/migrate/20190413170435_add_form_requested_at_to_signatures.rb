class AddFormRequestedAtToSignatures < ActiveRecord::Migration
  def up
    unless column_exists?(:signatures, :form_requested_at)
      add_column :signatures, :form_requested_at, :datetime
    end
  end

  def down
    if column_exists?(:signatures, :form_requested_at)
      remove_column :signatures, :form_requested_at
    end
  end
end
