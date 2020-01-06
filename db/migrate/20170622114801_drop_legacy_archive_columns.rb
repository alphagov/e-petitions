class DropLegacyArchiveColumns < ActiveRecord::Migration[4.2]
  def up
    remove_column :archived_petitions, :title
    remove_column :archived_petitions, :description
    remove_column :archived_petitions, :response
    remove_column :archived_petitions, :reason_for_rejection
  end

  def down
    add_column :archived_petitions, :title, :string, limit: 255
    add_column :archived_petitions, :description, :text
    add_column :archived_petitions, :response, :text
    add_column :archived_petitions, :reason_for_rejection, :text
  end
end
