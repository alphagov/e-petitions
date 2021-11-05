class AddDoNotAnonymizeToPetition < ActiveRecord::Migration[6.1]
  def change
    add_column :petitions, :do_not_anonymize, :boolean
    add_column :archived_petitions, :do_not_anonymize, :boolean
  end
end
