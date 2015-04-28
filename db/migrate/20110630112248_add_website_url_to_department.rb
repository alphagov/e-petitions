class AddWebsiteUrlToDepartment < ActiveRecord::Migration
  def self.up
    add_column :departments, :website_url, :string
  end

  def self.down
    remove_column :departments, :website_url
  end
end
