class AddDeadlineExtensionToPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  class Petition < ActiveRecord::Base; end

  def up
    unless column_exists?(:petitions, :deadline_extension)
      add_column :petitions, :deadline_extension, :integer

      Petition.find_each do |petition|
        petition.update(deadline_extension: 0)
      end

      change_column_default :petitions, :deadline_extension, 0
      change_column_null :petitions, :deadline_extension, false
    end
  end

  def down
    if column_exists?(:petitions, :deadline_extension)
      remove_column :petitions, :deadline_extension
    end
  end
end
