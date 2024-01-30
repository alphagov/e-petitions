class AddPublicEngagementUrlDebateSummaryUrlToDebateOutcome < ActiveRecord::Migration[6.1]
  def change
    add_column :debate_outcomes, :public_engagement_url, :string, limit: 500
    add_column :debate_outcomes, :debate_summary_url, :string, limit: 500
    add_column :archived_debate_outcomes, :public_engagement_url, :string, limit: 500
    add_column :archived_debate_outcomes, :debate_summary_url, :string, limit: 500
  end
end
