class ConvertPetitionIdToBigint < ActiveRecord::Migration[7.1]
  def up
    change_column :archived_debate_outcomes, :petition_id, :bigint
    change_column :archived_government_responses, :petition_id, :bigint
    change_column :archived_notes, :petition_id, :bigint
    change_column :archived_petition_emails, :petition_id, :bigint
    change_column :archived_rejections, :petition_id, :bigint
    change_column :constituency_petition_journals, :petition_id, :bigint
    change_column :country_petition_journals, :petition_id, :bigint
    change_column :debate_outcomes, :petition_id, :bigint
    change_column :email_requested_receipts, :petition_id, :bigint
    change_column :government_responses, :petition_id, :bigint
    change_column :invalidations, :petition_id, :bigint
    change_column :notes, :petition_id, :bigint
    change_column :petition_emails, :petition_id, :bigint
    change_column :petition_statistics, :petition_id, :bigint
    change_column :rejections, :petition_id, :bigint
    change_column :signatures, :petition_id, :bigint
    change_column :trending_domains, :petition_id, :bigint
    change_column :trending_ips, :petition_id, :bigint

    change_column :petitions, :id, :bigint
  end

  def down
    change_column :petitions, :id, :integer

    change_column :archived_debate_outcomes, :petition_id, :integer
    change_column :archived_government_responses, :petition_id, :integer
    change_column :archived_notes, :petition_id, :integer
    change_column :archived_petition_emails, :petition_id, :integer
    change_column :archived_rejections, :petition_id, :integer
    change_column :constituency_petition_journals, :petition_id, :integer
    change_column :country_petition_journals, :petition_id, :integer
    change_column :debate_outcomes, :petition_id, :integer
    change_column :email_requested_receipts, :petition_id, :integer
    change_column :government_responses, :petition_id, :integer
    change_column :invalidations, :petition_id, :integer
    change_column :notes, :petition_id, :integer
    change_column :petition_emails, :petition_id, :integer
    change_column :petition_statistics, :petition_id, :integer
    change_column :rejections, :petition_id, :integer
    change_column :signatures, :petition_id, :integer
    change_column :trending_domains, :petition_id, :integer
    change_column :trending_ips, :petition_id, :integer
  end
end
