class AddDebatePackUrlToDebateOutcomes < ActiveRecord::Migration[4.2]
  def change
    add_column :debate_outcomes, :debate_pack_url, :string, limit: 500
    add_column :archived_debate_outcomes, :debate_pack_url, :string, limit: 500
  end
end
