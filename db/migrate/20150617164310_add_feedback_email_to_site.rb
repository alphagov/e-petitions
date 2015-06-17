class AddFeedbackEmailToSite < ActiveRecord::Migration
  def change
    add_column :sites, :feedback_email, :string, limit: 100, null: false, default: 'feedback@petition.parliament.uk'
  end
end
