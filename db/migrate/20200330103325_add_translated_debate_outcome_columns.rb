class AddTranslatedDebateOutcomeColumns < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  class DebateOutcome < ActiveRecord::Base; end

  def change
    add_column :debate_outcomes, :transcript_url_en, :string, limit: 500
    add_column :debate_outcomes, :transcript_url_cy, :string, limit: 500
    add_column :debate_outcomes, :video_url_en, :string, limit: 500
    add_column :debate_outcomes, :video_url_cy, :string, limit: 500
    add_column :debate_outcomes, :debate_pack_url_en, :string, limit: 500
    add_column :debate_outcomes, :debate_pack_url_cy, :string, limit: 500
    add_column :debate_outcomes, :overview_en, :text
    add_column :debate_outcomes, :overview_cy, :text

    up_only do
      DebateOutcome.find_each do |outcome|
        outcome.update!(
          transcript_url_en: outcome.transcript_url,
          transcript_url_cy: outcome.transcript_url,
          video_url_en: outcome.video_url,
          video_url_cy: outcome.video_url,
          debate_pack_url_en: outcome.debate_pack_url,
          debate_pack_url_cy: outcome.debate_pack_url,
          overview_en: email.overview,
          overview_cy: email.overview
        )
      end
    end
  end
end
