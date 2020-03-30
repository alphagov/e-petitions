class DropOriginalDebateOutcomeColumns < ActiveRecord::Migration[5.2]
  def up
    remove_column :debate_outcomes, :transcript_url
    remove_column :debate_outcomes, :video_url
    remove_column :debate_outcomes, :debate_pack_url
    remove_column :debate_outcomes, :overview
  end

  def down
    add_column :debate_outcomes, :transcript_url, :string, limit: 500
    add_column :debate_outcomes, :video_url, :string, limit: 500
    add_column :debate_outcomes, :debate_pack_url, :string, limit: 500
    add_column :debate_outcomes, :overview, :text
  end
end
