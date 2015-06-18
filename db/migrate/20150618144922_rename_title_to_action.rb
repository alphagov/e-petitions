class RenameTitleToAction < ActiveRecord::Migration
  def change
    rename_column :petitions, :title, :action
    rename_index :petitions, 'index_petitions_on_title', 'index_petitions_on_action'
  end
end
