class ConvertSignatureIdToBigint < ActiveRecord::Migration[7.1]
  def up
    change_column :signatures, :invalidation_id, :bigint
    change_column :archived_signatures, :invalidation_id, :bigint

    change_column :archived_petitions, :parliament_id, :bigint
    change_column :domains, :canonical_domain_id, :bigint

    change_column :petitions, :locked_by_id, :bigint
    change_column :petitions, :moderated_by_id, :bigint
    change_column :archived_petitions, :locked_by_id, :bigint
    change_column :archived_petitions, :moderated_by_id, :bigint

    change_column :archived_debate_outcomes, :petition_id, :bigint
    change_column :archived_government_responses, :petition_id, :bigint
    change_column :archived_notes, :petition_id, :bigint
    change_column :archived_petition_emails, :petition_id, :bigint
    change_column :archived_rejections, :petition_id, :bigint
    change_column :archived_signatures, :petition_id, :bigint
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

    change_column :active_storage_attachments, :id, :bigint
    change_column :active_storage_blobs, :id, :bigint
    change_column :active_storage_variant_records, :id, :bigint
    change_column :admin_users, :id, :bigint
    change_column :archived_debate_outcomes, :id, :bigint
    change_column :archived_government_responses, :id, :bigint
    change_column :archived_notes, :id, :bigint
    change_column :archived_petition_emails, :id, :bigint
    change_column :archived_petition_mailshots, :id, :bigint
    change_column :archived_petitions, :id, :bigint
    change_column :archived_rejections, :id, :bigint
    change_column :archived_signatures, :id, :bigint
    change_column :constituencies, :id, :bigint
    change_column :constituency_petition_journals, :id, :bigint
    change_column :country_petition_journals, :id, :bigint
    change_column :debate_outcomes, :id, :bigint
    change_column :delayed_jobs, :id, :bigint
    change_column :domains, :id, :bigint
    change_column :email_requested_receipts, :id, :bigint
    change_column :feedback, :id, :bigint
    change_column :government_responses, :id, :bigint
    change_column :holidays, :id, :bigint
    change_column :invalidations, :id, :bigint
    change_column :locations, :id, :bigint
    change_column :notes, :id, :bigint
    change_column :parliaments, :id, :bigint
    change_column :petition_emails, :id, :bigint
    change_column :petition_mailshots, :id, :bigint
    change_column :petition_statistics, :id, :bigint
    change_column :petitions, :id, :bigint
    change_column :rate_limits, :id, :bigint
    change_column :regions, :id, :bigint
    change_column :rejection_reasons, :id, :bigint
    change_column :rejections, :id, :bigint
    change_column :signatures, :id, :bigint
    change_column :sites, :id, :bigint
    change_column :tasks, :id, :bigint
    change_column :trending_domains, :id, :bigint
    change_column :trending_ips, :id, :bigint
  end

  def down
    change_column :active_storage_attachments, :id, :integer
    change_column :active_storage_blobs, :id, :integer
    change_column :active_storage_variant_records, :id, :integer
    change_column :admin_users, :id, :integer
    change_column :archived_debate_outcomes, :id, :integer
    change_column :archived_government_responses, :id, :integer
    change_column :archived_notes, :id, :integer
    change_column :archived_petition_emails, :id, :integer
    change_column :archived_petition_mailshots, :id, :integer
    change_column :archived_petitions, :id, :integer
    change_column :archived_rejections, :id, :integer
    change_column :archived_signatures, :id, :integer
    change_column :constituencies, :id, :integer
    change_column :constituency_petition_journals, :id, :integer
    change_column :country_petition_journals, :id, :integer
    change_column :debate_outcomes, :id, :integer
    change_column :delayed_jobs, :id, :integer
    change_column :domains, :id, :integer
    change_column :email_requested_receipts, :id, :integer
    change_column :feedback, :id, :integer
    change_column :government_responses, :id, :integer
    change_column :holidays, :id, :integer
    change_column :invalidations, :id, :integer
    change_column :locations, :id, :integer
    change_column :notes, :id, :integer
    change_column :parliaments, :id, :integer
    change_column :petition_emails, :id, :integer
    change_column :petition_mailshots, :id, :integer
    change_column :petition_statistics, :id, :integer
    change_column :petitions, :id, :integer
    change_column :rate_limits, :id, :integer
    change_column :regions, :id, :integer
    change_column :rejection_reasons, :id, :integer
    change_column :rejections, :id, :integer
    change_column :signatures, :id, :integer
    change_column :sites, :id, :integer
    change_column :tasks, :id, :integer
    change_column :trending_domains, :id, :integer
    change_column :trending_ips, :id, :integer

    change_column :archived_debate_outcomes, :petition_id, :integer
    change_column :archived_government_responses, :petition_id, :integer
    change_column :archived_notes, :petition_id, :integer
    change_column :archived_petition_emails, :petition_id, :integer
    change_column :archived_rejections, :petition_id, :integer
    change_column :archived_signatures, :petition_id, :integer
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

    change_column :signatures, :invalidation_id, :integer
    change_column :archived_signatures, :invalidation_id, :integer

    change_column :archived_petitions, :parliament_id, :integer
    change_column :domains, :canonical_domain_id, :integer

    change_column :petitions, :locked_by_id, :integer
    change_column :petitions, :moderated_by_id, :integer
    change_column :archived_petitions, :locked_by_id, :integer
    change_column :archived_petitions, :moderated_by_id, :integer
  end
end
