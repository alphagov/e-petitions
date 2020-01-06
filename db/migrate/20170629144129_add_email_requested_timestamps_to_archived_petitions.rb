class AddEmailRequestedTimestampsToArchivedPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :archived_petitions, :email_requested_for_government_response_at, :datetime
    add_column :archived_petitions, :email_requested_for_debate_scheduled_at, :datetime
    add_column :archived_petitions, :email_requested_for_debate_outcome_at, :datetime
    add_column :archived_petitions, :email_requested_for_petition_email_at, :datetime
  end
end
