class AddUseMarkdownToPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  class Petition < ActiveRecord::Base; end

  def change
    add_column :petitions, :use_markdown, :boolean

    up_only do
      Petition.find_each do |petition|
        petition.update_column(:use_markdown, true)
      end
    end

    change_column_default :petitions, :use_markdown, from: nil, to: false
    change_column_null :petitions, :use_markdown, false
  end
end
