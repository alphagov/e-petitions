class AddEmailTimestampsToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :government_response_email_at, :datetime
    add_column :signatures, :debate_scheduled_email_at, :datetime
    add_column :signatures, :debate_outcome_email_at, :datetime
    add_column :signatures, :petition_email_at, :datetime
  end
end
