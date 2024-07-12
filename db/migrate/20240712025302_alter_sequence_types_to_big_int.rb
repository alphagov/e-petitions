class AlterSequenceTypesToBigInt < ActiveRecord::Migration[7.1]
  BIGINT_SEQUENCES = %w[
    active_storage_attachments_id_seq
    active_storage_blobs_id_seq
    active_storage_variant_records_id_seq
    admin_users_id_seq
    archived_debate_outcomes_id_seq
    archived_government_responses_id_seq
    archived_notes_id_seq
    archived_petition_emails_id_seq
    archived_petition_mailshots_id_seq
    archived_rejections_id_seq
    archived_signatures_id_seq
    constituencies_id_seq
    constituency_petition_journals_id_seq
    country_petition_journals_id_seq
    debate_outcomes_id_seq
    delayed_jobs_id_seq
    domains_id_seq
    email_requested_receipts_id_seq
    feedback_id_seq
    government_responses_id_seq
    holidays_id_seq
    invalidations_id_seq
    locations_id_seq
    notes_id_seq
    parliaments_id_seq
    petition_emails_id_seq
    petition_mailshots_id_seq
    petition_statistics_id_seq
    petitions_id_seq
    rate_limits_id_seq
    regions_id_seq
    rejection_reasons_id_seq
    rejections_id_seq
    signatures_id_seq
    sites_id_seq
    tasks_id_seq
    trending_domains_id_seq
    trending_ips_id_seq
    parliament_constituencies_id_seq
  ]

  INTEGER_SEQUENCES = %w[
    departments_id_seq
    tags_id_seq
    topics_id_seq
  ]

  def change
    up_only do
      BIGINT_SEQUENCES.each do |sequence|
        execute "ALTER SEQUENCE #{sequence} AS bigint MAXVALUE 9223372036854775807"
      end

      INTEGER_SEQUENCES.each do |sequence|
        execute "ALTER SEQUENCE #{sequence} AS integer MAXVALUE 2147483647"
      end

      execute "ALTER SEQUENCE archived_petitions_id_seq AS bigint MAXVALUE 299999"
    end
  end
end
