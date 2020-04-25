class AddSubmittedOnToPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  class Petition < ActiveRecord::Base; end

  def change
    add_column :petitions, :submitted_on_paper, :boolean
    add_column :petitions, :submitted_on, :date

    up_only do
      Petition.find_each do |petition|
        petition.update_column(:submitted_on_paper, false)
      end
    end

    change_column_default :petitions, :submitted_on_paper, from: nil, to: false
    change_column_null :petitions, :submitted_on_paper, false
  end
end
