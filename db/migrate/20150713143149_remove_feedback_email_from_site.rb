class RemoveFeedbackEmailFromSite < ActiveRecord::Migration
  def change
    remove_column :sites, :feedback_email, :string
  end
end
