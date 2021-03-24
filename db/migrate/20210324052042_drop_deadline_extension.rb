class DropDeadlineExtension < ActiveRecord::Migration[5.2]
  def up
    if column_exists?(:petitions, :deadline_extension)
      remove_column :petitions, :deadline_extension
    end
  end

  def down
    # Do nothing
  end
end
