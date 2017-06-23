class AllowForLongerEmailsInSite < ActiveRecord::Migration[4.2]
  def up
    change_column :sites, :email_from, :string, limit: 100, default: '"Petitions: UK Government and Parliament" <no-reply@petition.parliament.uk>'
    change_column :sites, :feedback_email, :string, limit: 100, default: '"Petitions: UK Government and Parliament" <feedback@petition.parliament.uk>'
  end

  def down
    change_column :sites, :email_from, :string, limit: 50, default: 'no-reply@petition.parliament.uk'
    change_column :sites, :feedback_email, :string, limit: 100, default: 'feedback@petition.parliament.uk'
  end
end
