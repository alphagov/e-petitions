class AddImageLoadedAtToSignatures < ActiveRecord::Migration
  def up
    unless column_exists?(:signatures, :image_loaded_at)
      add_column :signatures, :image_loaded_at, :datetime
    end
  end

  def down
    if column_exists?(:signatures, :image_loaded_at)
      remove_column :signatures, :image_loaded_at
    end
  end
end
