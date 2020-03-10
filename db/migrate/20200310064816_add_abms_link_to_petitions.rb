class AddAbmsLinkToPetitions < ActiveRecord::Migration[5.2]
  def change
    add_column :petitions, :abms_link_en, :string
    add_column :petitions, :abms_link_cy, :string
  end
end
