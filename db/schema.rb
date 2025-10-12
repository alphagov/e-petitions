# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_10_12_120752) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "intarray"
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", limit: 255, null: false
    t.string "persistence_token", limit: 255
    t.string "encrypted_password", limit: 255
    t.string "password_salt", limit: 255
    t.integer "sign_in_count", default: 0
    t.integer "failed_attempts", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "role", limit: 10, null: false
    t.boolean "force_password_reset", default: true
    t.datetime "password_changed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["last_name", "first_name"], name: "index_admin_users_on_last_name_and_first_name"
  end

  create_table "archived_debate_outcomes", force: :cascade do |t|
    t.bigint "petition_id", null: false
    t.date "debated_on"
    t.string "transcript_url", limit: 500
    t.string "video_url", limit: 500
    t.text "overview"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "debated", default: true, null: false
    t.string "commons_image_file_name"
    t.string "commons_image_content_type"
    t.integer "commons_image_file_size"
    t.datetime "commons_image_updated_at", precision: nil
    t.string "debate_pack_url", limit: 500
    t.string "public_engagement_url", limit: 500
    t.string "debate_summary_url", limit: 500
    t.index ["petition_id", "debated_on"], name: "index_archived_debate_outcomes_on_petition_id_and_debated_on"
    t.index ["petition_id"], name: "index_archived_debate_outcomes_on_petition_id", unique: true
    t.index ["updated_at"], name: "index_archived_debate_outcomes_on_updated_at"
  end

  create_table "archived_government_responses", force: :cascade do |t|
    t.bigint "petition_id"
    t.string "summary", limit: 500, null: false
    t.text "details"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.date "responded_on"
    t.index ["petition_id"], name: "index_archived_government_responses_on_petition_id", unique: true
    t.index ["updated_at"], name: "index_archived_government_responses_on_updated_at"
  end

  create_table "archived_notes", force: :cascade do |t|
    t.bigint "petition_id"
    t.text "details"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["petition_id"], name: "index_archived_notes_on_petition_id", unique: true
  end

  create_table "archived_petition_emails", force: :cascade do |t|
    t.bigint "petition_id"
    t.string "subject", null: false
    t.text "body"
    t.string "sent_by"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "email_count"
    t.datetime "emails_enqueued_at", precision: nil
    t.index ["petition_id"], name: "index_archived_petition_emails_on_petition_id"
  end

  create_table "archived_petition_mailshots", force: :cascade do |t|
    t.bigint "petition_id"
    t.string "subject", null: false
    t.text "body"
    t.string "sent_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["petition_id"], name: "index_archived_petition_mailshots_on_petition_id"
  end

  create_table "archived_petitions", force: :cascade do |t|
    t.string "state", limit: 10, default: "closed", null: false
    t.datetime "opened_at", precision: nil
    t.datetime "closed_at", precision: nil
    t.integer "signature_count", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "parliament_id", null: false
    t.string "action", limit: 255
    t.string "background", limit: 300
    t.text "additional_details"
    t.datetime "government_response_at", precision: nil
    t.date "scheduled_debate_date"
    t.datetime "last_signed_at", precision: nil
    t.datetime "response_threshold_reached_at", precision: nil
    t.datetime "debate_threshold_reached_at", precision: nil
    t.datetime "rejected_at", precision: nil
    t.datetime "debate_outcome_at", precision: nil
    t.datetime "moderation_threshold_reached_at", precision: nil
    t.string "debate_state", limit: 30
    t.datetime "stopped_at", precision: nil
    t.boolean "special_consideration"
    t.jsonb "signatures_by_constituency"
    t.jsonb "signatures_by_country"
    t.datetime "email_requested_for_government_response_at", precision: nil
    t.datetime "email_requested_for_debate_scheduled_at", precision: nil
    t.datetime "email_requested_for_debate_outcome_at", precision: nil
    t.datetime "email_requested_for_petition_email_at", precision: nil
    t.integer "tags", default: [], null: false, array: true
    t.datetime "locked_at", precision: nil
    t.bigint "locked_by_id"
    t.integer "moderation_lag"
    t.text "committee_note"
    t.integer "departments", default: [], null: false, array: true
    t.datetime "anonymized_at", precision: nil
    t.bigint "moderated_by_id"
    t.integer "topics", default: [], null: false, array: true
    t.datetime "email_requested_for_petition_mailshot_at", precision: nil
    t.boolean "do_not_anonymize"
    t.text "reason_for_removal"
    t.string "state_at_removal", limit: 10
    t.datetime "removed_at", precision: nil
    t.halfvec "embedding", limit: 1024
    t.datetime "published_at", precision: nil
    t.string "response_state", limit: 30, default: "pending", null: false
    t.index "to_tsvector('english'::regconfig, (action)::text)", name: "index_archived_petitions_on_action", using: :gin
    t.index "to_tsvector('english'::regconfig, (background)::text)", name: "index_archived_petitions_on_background", using: :gin
    t.index "to_tsvector('english'::regconfig, additional_details)", name: "index_archived_petitions_on_additional_details", using: :gin
    t.index ["anonymized_at"], name: "index_archived_petitions_on_anonymized_at"
    t.index ["debate_state", "parliament_id"], name: "index_archived_petitions_on_debate_state_and_parliament_id"
    t.index ["departments"], name: "index_archived_petitions_on_departments", opclass: :gin__int_ops, using: :gin
    t.index ["embedding"], name: "index_archived_petitions_on_embedding", opclass: :halfvec_cosine_ops, using: :hnsw
    t.index ["government_response_at", "parliament_id"], name: "index_archived_petitions_on_response_at_and_parliament_id"
    t.index ["locked_by_id"], name: "index_archived_petitions_on_locked_by_id"
    t.index ["moderated_by_id"], name: "index_archived_petitions_on_moderated_by_id"
    t.index ["moderation_threshold_reached_at", "moderation_lag"], name: "index_archived_petitions_on_mt_reached_at_and_moderation_lag"
    t.index ["parliament_id"], name: "index_archived_petitions_on_parliament_id"
    t.index ["response_state"], name: "index_archived_petitions_on_response_state"
    t.index ["signature_count", "created_at"], name: "index_archived_petitions_on_signature_count_and_created_at", order: :desc
    t.index ["signature_count"], name: "index_archived_petitions_on_signature_count"
    t.index ["state", "closed_at"], name: "index_archived_petitions_on_state_and_closed_at"
    t.index ["state", "parliament_id"], name: "index_archived_petitions_on_state_and_parliament_id"
    t.index ["tags"], name: "index_archived_petitions_on_tags", opclass: :gin__int_ops, using: :gin
    t.index ["topics"], name: "index_archived_petitions_on_topics", opclass: :gin__int_ops, using: :gin
  end

  create_table "archived_rejections", force: :cascade do |t|
    t.bigint "petition_id"
    t.string "code", limit: 50, null: false
    t.text "details"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["petition_id"], name: "index_archived_rejections_on_petition_id", unique: true
  end

  create_table "archived_signatures", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "state", limit: 20, default: "pending", null: false
    t.string "perishable_token", limit: 255
    t.string "postcode", limit: 255
    t.string "ip_address", limit: 20
    t.bigint "petition_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "notify_by_email", default: false
    t.string "email", limit: 255
    t.string "unsubscribe_token"
    t.string "constituency_id"
    t.datetime "validated_at", precision: nil
    t.integer "number"
    t.string "location_code", limit: 30
    t.datetime "invalidated_at", precision: nil
    t.bigint "invalidation_id"
    t.datetime "government_response_email_at", precision: nil
    t.datetime "debate_scheduled_email_at", precision: nil
    t.datetime "debate_outcome_email_at", precision: nil
    t.datetime "petition_email_at", precision: nil
    t.uuid "uuid"
    t.boolean "creator", default: false, null: false
    t.boolean "sponsor", default: false, null: false
    t.datetime "anonymized_at", precision: nil
    t.datetime "petition_mailshot_at", precision: nil
    t.index "((ip_address)::inet)", name: "index_archived_signatures_on_inet"
    t.index "((regexp_replace(\"left\"(lower((email)::text), (\"position\"((email)::text, '@'::text) - 1)), '\\.|\\+.+'::text, ''::text, 'g'::text) || \"substring\"(lower((email)::text), \"position\"((email)::text, '@'::text))))", name: "index_archived_signatures_on_lower_normalized_email"
    t.index "\"left\"((postcode)::text, '-3'::integer), petition_id", name: "index_archived_signatures_on_sector_and_petition_id"
    t.index "\"left\"((postcode)::text, '-3'::integer), state, petition_id", name: "index_archived_signatures_on_sector_and_state_and_petition_id"
    t.index "\"substring\"((email)::text, (\"position\"((email)::text, '@'::text) + 1))", name: "index_archived_signatures_on_domain"
    t.index "lower((email)::text)", name: "index_archived_signatures_on_lower_email"
    t.index "lower((name)::text)", name: "index_archived_signatures_on_name"
    t.index ["constituency_id"], name: "index_archived_signatures_on_constituency_id"
    t.index ["created_at", "ip_address", "petition_id"], name: "index_archived_signatures_on_creation_ip_and_petition_id"
    t.index ["email", "petition_id", "name"], name: "index_archived_signatures_on_email_and_petition_id_and_name", unique: true
    t.index ["invalidation_id"], name: "index_archived_signatures_on_invalidation_id"
    t.index ["ip_address", "petition_id"], name: "index_archived_signatures_on_ip_address_and_petition_id"
    t.index ["petition_id", "anonymized_at"], name: "index_archived_signatures_on_petition_id_and_anonymized_at"
    t.index ["petition_id", "location_code"], name: "index_archived_signatures_on_petition_id_and_location_code"
    t.index ["petition_id"], name: "index_archived_signatures_on_petition_id"
    t.index ["petition_id"], name: "index_archived_signatures_on_petition_id_where_creator_is_true", unique: true, where: "(creator = true)"
    t.index ["petition_id"], name: "index_archived_signatures_on_petition_id_where_sponsor_is_true", where: "(sponsor = true)"
    t.index ["postcode", "petition_id"], name: "index_archived_signatures_on_postcode_and_petition_id"
    t.index ["postcode", "state", "petition_id"], name: "index_archived_signatures_on_postcode_and_state_and_petition_id"
    t.index ["state", "petition_id"], name: "index_archived_signatures_on_state_and_petition_id"
    t.index ["updated_at"], name: "index_archived_signatures_on_updated_at"
    t.index ["uuid"], name: "index_archived_signatures_on_uuid"
    t.index ["validated_at"], name: "index_archived_signatures_on_validated_at"
  end

  create_table "constituencies", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "slug", limit: 100, null: false
    t.string "external_id", limit: 30, null: false
    t.string "ons_code", limit: 10, null: false
    t.string "mp_id", limit: 30
    t.string "mp_name", limit: 100
    t.date "mp_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "example_postcode", limit: 30
    t.string "party", limit: 100
    t.string "region_id", limit: 30
    t.date "start_date"
    t.date "end_date"
    t.index ["external_id"], name: "index_constituencies_on_external_id", unique: true
    t.index ["region_id"], name: "index_constituencies_on_region_id"
    t.index ["slug"], name: "index_constituencies_on_slug", unique: true, where: "(end_date IS NULL)"
  end

  create_table "constituency_petition_journals", force: :cascade do |t|
    t.string "constituency_id", null: false
    t.bigint "petition_id", null: false
    t.integer "signature_count", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "last_signed_at", precision: nil
    t.index ["petition_id", "constituency_id"], name: "idx_constituency_petition_journal_uniqueness", unique: true
  end

  create_table "country_petition_journals", force: :cascade do |t|
    t.bigint "petition_id", null: false
    t.integer "signature_count", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "location_code", limit: 30
    t.datetime "last_signed_at", precision: nil
    t.index ["petition_id", "location_code"], name: "index_country_petition_journals_on_petition_and_location", unique: true
  end

  create_table "debate_outcomes", force: :cascade do |t|
    t.bigint "petition_id", null: false
    t.date "debated_on"
    t.string "transcript_url", limit: 500
    t.string "video_url", limit: 500
    t.text "overview"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "debated", default: true, null: false
    t.string "commons_image_file_name"
    t.string "commons_image_content_type"
    t.integer "commons_image_file_size"
    t.datetime "commons_image_updated_at", precision: nil
    t.string "debate_pack_url", limit: 500
    t.string "public_engagement_url", limit: 500
    t.string "debate_summary_url", limit: 500
    t.index ["petition_id", "debated_on"], name: "index_debate_outcomes_on_petition_id_and_debated_on"
    t.index ["petition_id"], name: "index_debate_outcomes_on_petition_id", unique: true
    t.index ["updated_at"], name: "index_debate_outcomes_on_updated_at"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler"
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "queue", limit: 255
    t.index ["priority", "run_at"], name: "index_delayed_jobs_on_priority_and_run_at"
  end

  create_table "departments", id: :serial, force: :cascade do |t|
    t.string "external_id", limit: 30
    t.string "name", limit: 100, null: false
    t.string "acronym", limit: 10
    t.string "url", limit: 100
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "dissolution_notifications", id: :uuid, default: nil, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "domains", force: :cascade do |t|
    t.bigint "canonical_domain_id"
    t.string "name", limit: 100, null: false
    t.string "strip_characters", limit: 10
    t.string "strip_extension", limit: 10, default: "+"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["canonical_domain_id"], name: "index_domains_on_canonical_domain_id"
    t.index ["name"], name: "index_domains_on_name", unique: true
  end

  create_table "email_requested_receipts", force: :cascade do |t|
    t.bigint "petition_id"
    t.datetime "government_response", precision: nil
    t.datetime "debate_outcome", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "debate_scheduled", precision: nil
    t.datetime "petition_email", precision: nil
    t.datetime "petition_mailshot", precision: nil
    t.index ["petition_id"], name: "index_email_requested_receipts_on_petition_id"
  end

  create_table "feedback", force: :cascade do |t|
    t.string "comment", limit: 32768, null: false
    t.string "petition_link_or_title"
    t.string "email"
    t.string "user_agent"
    t.string "ip_address", limit: 20
    t.datetime "created_at", precision: nil
    t.index ["ip_address"], name: "index_feedback_on_ip_address"
  end

  create_table "government_responses", force: :cascade do |t|
    t.bigint "petition_id"
    t.string "summary", limit: 500, null: false
    t.text "details"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.date "responded_on"
    t.index ["petition_id"], name: "index_government_responses_on_petition_id", unique: true
    t.index ["updated_at"], name: "index_government_responses_on_updated_at"
  end

  create_table "holidays", force: :cascade do |t|
    t.date "christmas_start"
    t.date "christmas_end"
    t.date "easter_start"
    t.date "easter_end"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "invalidations", force: :cascade do |t|
    t.string "summary", limit: 255, null: false
    t.string "details", limit: 10000
    t.bigint "petition_id"
    t.string "name", limit: 255
    t.string "postcode", limit: 255
    t.string "ip_address", limit: 20
    t.string "email", limit: 255
    t.datetime "created_after", precision: nil
    t.datetime "created_before", precision: nil
    t.string "constituency_id", limit: 30
    t.string "location_code", limit: 30
    t.integer "matching_count", default: 0, null: false
    t.integer "invalidated_count", default: 0, null: false
    t.datetime "enqueued_at", precision: nil
    t.datetime "started_at", precision: nil
    t.datetime "cancelled_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "counted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "domain", limit: 255
    t.index "to_tsvector('english'::regconfig, (details)::text)", name: "ft_index_invalidations_on_details", using: :gin
    t.index "to_tsvector('english'::regconfig, (id)::text)", name: "ft_index_invalidations_on_id", using: :gin
    t.index "to_tsvector('english'::regconfig, (petition_id)::text)", name: "ft_index_invalidations_on_petition_id", using: :gin
    t.index "to_tsvector('english'::regconfig, (summary)::text)", name: "ft_index_invalidations_on_summary", using: :gin
    t.index ["cancelled_at"], name: "index_invalidations_on_cancelled_at"
    t.index ["completed_at"], name: "index_invalidations_on_completed_at"
    t.index ["petition_id"], name: "index_invalidations_on_petition_id"
    t.index ["started_at"], name: "index_invalidations_on_started_at"
  end

  create_table "locations", force: :cascade do |t|
    t.string "code", limit: 30, null: false
    t.string "name", limit: 100, null: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["code"], name: "index_locations_on_code", unique: true
    t.index ["name"], name: "index_locations_on_name", unique: true
    t.index ["start_date", "end_date"], name: "index_locations_on_start_date_and_end_date"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "petition_id"
    t.text "details"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["petition_id"], name: "index_notes_on_petition_id", unique: true
  end

  create_table "pages", force: :cascade do |t|
    t.string "slug", limit: 100, null: false
    t.string "title", limit: 100, null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "enabled", default: true, null: false
    t.boolean "redirect", default: false, null: false
    t.string "redirect_url"
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "parliament_constituencies", force: :cascade do |t|
    t.bigint "parliament_id", null: false
    t.string "constituency_id", limit: 30, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["constituency_id"], name: "index_parliament_constituencies_on_constituency_id"
    t.index ["parliament_id", "constituency_id"], name: "idx_on_parliament_id_constituency_id_ced79e105b", unique: true
  end

  create_table "parliaments", force: :cascade do |t|
    t.datetime "dissolution_at", precision: nil
    t.text "dissolution_message"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "dissolution_heading", limit: 100
    t.string "dissolution_faq_url", limit: 500
    t.string "dissolved_heading", limit: 100
    t.text "dissolved_message"
    t.datetime "notification_cutoff_at", precision: nil
    t.datetime "registration_closed_at", precision: nil
    t.string "government", limit: 100
    t.datetime "opening_at", precision: nil
    t.datetime "archived_at", precision: nil
    t.integer "threshold_for_response", default: 10000, null: false
    t.integer "threshold_for_debate", default: 100000, null: false
    t.integer "petition_duration", default: 6
    t.datetime "archiving_started_at", precision: nil
    t.date "election_date"
    t.boolean "show_dissolution_notification", default: false, null: false
    t.string "government_response_heading"
    t.text "government_response_description"
    t.string "government_response_status"
    t.string "parliamentary_debate_heading"
    t.text "parliamentary_debate_description"
    t.string "parliamentary_debate_status"
    t.datetime "dissolution_emails_sent_at"
    t.datetime "closure_scheduled_at"
    t.datetime "state_opening_at"
    t.virtual "period", type: :string, as: "\nCASE\n    WHEN (state_opening_at IS NULL) THEN (date_part('year'::text, created_at) || '-'::text)\n    WHEN (dissolution_at IS NULL) THEN (date_part('year'::text, state_opening_at) || '-'::text)\n    ELSE ((date_part('year'::text, state_opening_at) || '-'::text) || date_part('year'::text, dissolution_at))\nEND", stored: true
  end

  create_table "petition_emails", force: :cascade do |t|
    t.bigint "petition_id"
    t.string "subject", null: false
    t.text "body"
    t.string "sent_by"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "email_count"
    t.datetime "emails_enqueued_at", precision: nil
    t.index ["petition_id"], name: "index_petition_emails_on_petition_id"
  end

  create_table "petition_mailshots", force: :cascade do |t|
    t.bigint "petition_id"
    t.string "subject", null: false
    t.text "body"
    t.string "sent_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["petition_id"], name: "index_petition_mailshots_on_petition_id"
  end

  create_table "petition_statistics", force: :cascade do |t|
    t.bigint "petition_id"
    t.datetime "refreshed_at", precision: nil
    t.integer "duplicate_emails"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "pending_rate"
    t.integer "subscribers"
    t.index ["petition_id"], name: "index_petition_statistics_on_petition_id", unique: true
  end

  create_table "petitions", force: :cascade do |t|
    t.string "action", limit: 255, null: false
    t.text "additional_details"
    t.string "state", limit: 10, default: "pending", null: false
    t.datetime "open_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "closed_at", precision: nil
    t.integer "signature_count", default: 0
    t.boolean "notified_by_email", default: false
    t.string "background", limit: 300
    t.string "sponsor_token", limit: 255
    t.datetime "government_response_at", precision: nil
    t.date "scheduled_debate_date"
    t.datetime "last_signed_at", precision: nil
    t.datetime "response_threshold_reached_at", precision: nil
    t.datetime "debate_threshold_reached_at", precision: nil
    t.datetime "rejected_at", precision: nil
    t.datetime "debate_outcome_at", precision: nil
    t.datetime "moderation_threshold_reached_at", precision: nil
    t.string "debate_state", limit: 30, default: "pending"
    t.datetime "stopped_at", precision: nil
    t.boolean "special_consideration"
    t.datetime "archived_at", precision: nil
    t.datetime "archiving_started_at", precision: nil
    t.integer "tags", default: [], null: false, array: true
    t.datetime "locked_at", precision: nil
    t.bigint "locked_by_id"
    t.integer "moderation_lag"
    t.datetime "signature_count_reset_at", precision: nil
    t.datetime "signature_count_validated_at", precision: nil
    t.text "committee_note"
    t.integer "departments", default: [], null: false, array: true
    t.datetime "anonymized_at", precision: nil
    t.bigint "moderated_by_id"
    t.integer "deadline_extension", default: 0, null: false
    t.integer "topics", default: [], null: false, array: true
    t.boolean "do_not_anonymize"
    t.text "reason_for_removal"
    t.string "state_at_removal", limit: 10
    t.datetime "removed_at", precision: nil
    t.halfvec "embedding", limit: 1024
    t.datetime "published_at", precision: nil
    t.string "response_state", limit: 30, default: "pending", null: false
    t.index "((last_signed_at > signature_count_validated_at))", name: "index_petitions_on_validated_at_and_signed_at"
    t.index "to_tsvector('english'::regconfig, (action)::text)", name: "index_petitions_on_action", using: :gin
    t.index "to_tsvector('english'::regconfig, (background)::text)", name: "index_petitions_on_background", using: :gin
    t.index "to_tsvector('english'::regconfig, additional_details)", name: "index_petitions_on_additional_details", using: :gin
    t.index ["anonymized_at"], name: "index_petitions_on_anonymized_at"
    t.index ["archived_at"], name: "index_petitions_on_archived_at"
    t.index ["created_at", "state"], name: "index_petitions_on_created_at_and_state"
    t.index ["debate_state"], name: "index_petitions_on_debate_state"
    t.index ["debate_threshold_reached_at"], name: "index_petitions_on_debate_threshold_reached_at"
    t.index ["departments"], name: "index_petitions_on_departments", opclass: :gin__int_ops, using: :gin
    t.index ["embedding"], name: "index_petitions_on_embedding", opclass: :halfvec_cosine_ops, using: :hnsw
    t.index ["government_response_at", "state"], name: "index_petitions_on_government_response_at_and_state"
    t.index ["last_signed_at"], name: "index_petitions_on_last_signed_at"
    t.index ["locked_by_id"], name: "index_petitions_on_locked_by_id"
    t.index ["moderated_by_id"], name: "index_petitions_on_moderated_by_id"
    t.index ["moderation_threshold_reached_at", "moderation_lag"], name: "index_petitions_on_mt_reached_at_and_moderation_lag"
    t.index ["response_state"], name: "index_petitions_on_response_state"
    t.index ["response_threshold_reached_at"], name: "index_petitions_on_response_threshold_reached_at"
    t.index ["signature_count", "created_at"], name: "index_petitions_on_signature_count_and_created_at", order: :desc
    t.index ["signature_count", "state"], name: "index_petitions_on_signature_count_and_state"
    t.index ["state", "open_at", "created_at"], name: "index_petitions_on_state_and_open_at_and_created_at", order: { open_at: :desc, created_at: :desc }
    t.index ["state", "signature_count", "created_at"], name: "index_petitions_on_state_and_signature_count_and_created_at", order: { signature_count: :desc, created_at: :desc }
    t.index ["state"], name: "index_petitions_on_state"
    t.index ["tags"], name: "index_petitions_on_tags", opclass: :gin__int_ops, using: :gin
    t.index ["topics"], name: "index_petitions_on_topics", opclass: :gin__int_ops, using: :gin
  end

  create_table "privacy_notifications", id: :uuid, default: nil, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "ignore_petitions_before", precision: nil, null: false
  end

  create_table "rate_limits", force: :cascade do |t|
    t.integer "burst_rate", default: 1, null: false
    t.integer "burst_period", default: 60, null: false
    t.integer "sustained_rate", default: 5, null: false
    t.integer "sustained_period", default: 300, null: false
    t.string "allowed_domains", limit: 10000, default: "", null: false
    t.string "allowed_ips", limit: 10000, default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "blocked_domains", limit: 50000, default: "", null: false
    t.string "blocked_ips", limit: 50000, default: "", null: false
    t.boolean "geoblocking_enabled", default: false, null: false
    t.string "countries", limit: 2000, default: "", null: false
    t.integer "country_burst_rate", default: 1, null: false
    t.integer "country_sustained_rate", default: 60, null: false
    t.boolean "country_rate_limits_enabled", default: false, null: false
    t.string "ignored_domains", limit: 10000, default: "", null: false
    t.boolean "enable_logging_of_trending_items", default: false, null: false
    t.integer "threshold_for_logging_trending_items", default: 100, null: false
    t.integer "threshold_for_notifying_trending_items", default: 200, null: false
    t.string "trending_items_notification_url"
    t.integer "creator_rate", default: 2, null: false
    t.integer "sponsor_rate", default: 5, null: false
    t.integer "feedback_rate", default: 2, null: false
    t.string "blocked_emails", limit: 50000, default: "", null: false
  end

  create_table "regions", force: :cascade do |t|
    t.string "external_id", limit: 30, null: false
    t.string "name", limit: 50, null: false
    t.string "ons_code", limit: 10, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["external_id"], name: "index_regions_on_external_id", unique: true
    t.index ["name"], name: "index_regions_on_name", unique: true
    t.index ["ons_code"], name: "index_regions_on_ons_code", unique: true
  end

  create_table "rejection_reasons", force: :cascade do |t|
    t.string "code", limit: 30, null: false
    t.string "title", limit: 100, null: false
    t.string "description", limit: 2000, null: false
    t.boolean "hidden", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["code"], name: "index_rejection_reasons_on_code", unique: true
    t.index ["title"], name: "index_rejection_reasons_on_title", unique: true
  end

  create_table "rejections", force: :cascade do |t|
    t.bigint "petition_id"
    t.string "code", limit: 50, null: false
    t.text "details"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["petition_id"], name: "index_rejections_on_petition_id", unique: true
  end

  create_table "signatures", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "state", limit: 20, default: "pending", null: false
    t.string "perishable_token", limit: 255
    t.string "postcode", limit: 255
    t.string "ip_address", limit: 20
    t.bigint "petition_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "notify_by_email", default: false
    t.string "email", limit: 255
    t.string "unsubscribe_token"
    t.string "constituency_id"
    t.datetime "validated_at", precision: nil
    t.integer "number"
    t.boolean "seen_signed_confirmation_page", default: false, null: false
    t.string "location_code", limit: 30
    t.datetime "invalidated_at", precision: nil
    t.bigint "invalidation_id"
    t.datetime "government_response_email_at", precision: nil
    t.datetime "debate_scheduled_email_at", precision: nil
    t.datetime "debate_outcome_email_at", precision: nil
    t.datetime "petition_email_at", precision: nil
    t.uuid "uuid"
    t.datetime "archived_at", precision: nil
    t.integer "email_count", default: 0, null: false
    t.boolean "sponsor", default: false, null: false
    t.boolean "creator", default: false, null: false
    t.string "signed_token"
    t.string "validated_ip"
    t.string "canonical_email"
    t.datetime "anonymized_at", precision: nil
    t.datetime "petition_mailshot_at", precision: nil
    t.index "((ip_address)::inet)", name: "index_signatures_on_inet"
    t.index "((regexp_replace(\"left\"(lower((email)::text), (\"position\"((email)::text, '@'::text) - 1)), '\\.|\\+.+'::text, ''::text, 'g'::text) || \"substring\"(lower((email)::text), \"position\"((email)::text, '@'::text))))", name: "index_signatures_on_lower_normalized_email"
    t.index "\"left\"((postcode)::text, '-3'::integer), petition_id", name: "index_signatures_on_sector_and_petition_id"
    t.index "\"left\"((postcode)::text, '-3'::integer), state, petition_id", name: "index_signatures_on_sector_and_state_and_petition_id"
    t.index "\"substring\"((email)::text, (\"position\"((email)::text, '@'::text) + 1))", name: "index_signatures_on_domain"
    t.index "lower((email)::text)", name: "index_signatures_on_lower_email"
    t.index "lower((name)::text)", name: "index_signatures_on_name"
    t.index ["archived_at", "petition_id"], name: "index_signatures_on_archived_at_and_petition_id"
    t.index ["canonical_email"], name: "index_signatures_on_canonical_email"
    t.index ["constituency_id"], name: "index_signatures_on_constituency_id"
    t.index ["created_at", "ip_address", "petition_id"], name: "index_signatures_on_created_at_and_ip_address_and_petition_id"
    t.index ["email", "petition_id", "name"], name: "index_signatures_on_email_and_petition_id_and_name", unique: true
    t.index ["invalidation_id"], name: "index_signatures_on_invalidation_id"
    t.index ["ip_address", "petition_id"], name: "index_signatures_on_ip_address_and_petition_id"
    t.index ["petition_id", "anonymized_at"], name: "index_signatures_on_petition_id_and_anonymized_at"
    t.index ["petition_id", "location_code"], name: "index_signatures_on_petition_id_and_location_code"
    t.index ["petition_id"], name: "index_signatures_on_petition_id"
    t.index ["petition_id"], name: "index_signatures_on_petition_id_where_creator_is_true", unique: true, where: "(creator = true)"
    t.index ["petition_id"], name: "index_signatures_on_petition_id_where_sponsor_is_true", where: "(sponsor = true)"
    t.index ["postcode", "petition_id"], name: "index_signatures_on_postcode_and_petition_id"
    t.index ["postcode", "state", "petition_id"], name: "index_signatures_on_postcode_and_state_and_petition_id"
    t.index ["state", "petition_id"], name: "index_signatures_on_state_and_petition_id"
    t.index ["updated_at"], name: "index_signatures_on_updated_at"
    t.index ["uuid"], name: "index_signatures_on_uuid"
    t.index ["validated_at"], name: "index_signatures_on_validated_at"
  end

  create_table "sites", force: :cascade do |t|
    t.string "title", limit: 50, default: "Petition parliament", null: false
    t.string "url", limit: 50, default: "https://petition.parliament.uk", null: false
    t.string "email_from", limit: 100, default: "\"Petitions: UK Government and Parliament\" <no-reply@petition.parliament.uk>", null: false
    t.string "username", limit: 30
    t.string "password_digest", limit: 60
    t.boolean "enabled", default: true, null: false
    t.boolean "protected", default: false, null: false
    t.integer "petition_duration", default: 6, null: false
    t.integer "minimum_number_of_sponsors", default: 5, null: false
    t.integer "maximum_number_of_sponsors", default: 20, null: false
    t.integer "threshold_for_moderation", default: 5, null: false
    t.integer "threshold_for_response", default: 10000, null: false
    t.integer "threshold_for_debate", default: 100000, null: false
    t.datetime "last_checked_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "feedback_email", limit: 100, default: "\"Petitions: UK Government and Parliament\" <petitionscommittee@parliament.uk>", null: false
    t.string "moderate_url", limit: 50, default: "https://moderate.petition.parliament.uk", null: false
    t.datetime "last_petition_created_at", precision: nil
    t.integer "login_timeout", default: 1800, null: false
    t.jsonb "feature_flags", default: {}, null: false
    t.datetime "signature_count_updated_at", precision: nil
    t.integer "signature_count_interval", default: 60, null: false
    t.boolean "update_signature_counts", default: false, null: false
    t.integer "threshold_for_moderation_delay", default: 500, null: false
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "description", limit: 200
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index "to_tsvector('english'::regconfig, (description)::text)", name: "index_ft_tags_on_description", using: :gin
    t.index "to_tsvector('english'::regconfig, (name)::text)", name: "index_ft_tags_on_name", using: :gin
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name", limit: 60, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_tasks_on_name", unique: true
  end

  create_table "topics", id: :serial, force: :cascade do |t|
    t.string "code", limit: 100, null: false
    t.string "name", limit: 100, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["code"], name: "index_topics_on_code", unique: true
    t.index ["name"], name: "index_topics_on_name", unique: true
  end

  create_table "trending_domains", force: :cascade do |t|
    t.bigint "petition_id"
    t.string "domain", limit: 100, null: false
    t.integer "count", null: false
    t.datetime "starts_at", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["created_at", "count"], name: "index_trending_domains_on_created_at_and_count", order: { count: :desc }
    t.index ["domain", "petition_id"], name: "index_trending_domains_on_domain_and_petition_id"
    t.index ["petition_id"], name: "index_trending_domains_on_petition_id"
  end

  create_table "trending_ips", force: :cascade do |t|
    t.bigint "petition_id"
    t.inet "ip_address", null: false
    t.string "country_code", limit: 30, null: false
    t.integer "count", null: false
    t.datetime "starts_at", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["created_at", "count"], name: "index_trending_ips_on_created_at_and_count", order: { count: :desc }
    t.index ["ip_address", "petition_id"], name: "index_trending_ips_on_ip_address_and_petition_id"
    t.index ["petition_id"], name: "index_trending_ips_on_petition_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "archived_debate_outcomes", "archived_petitions", column: "petition_id", on_delete: :cascade
  add_foreign_key "archived_government_responses", "archived_petitions", column: "petition_id", on_delete: :cascade
  add_foreign_key "archived_notes", "archived_petitions", column: "petition_id", on_delete: :cascade
  add_foreign_key "archived_petition_emails", "archived_petitions", column: "petition_id", on_delete: :cascade
  add_foreign_key "archived_petition_mailshots", "archived_petitions", column: "petition_id"
  add_foreign_key "archived_petitions", "admin_users", column: "moderated_by_id"
  add_foreign_key "archived_petitions", "parliaments"
  add_foreign_key "archived_rejections", "archived_petitions", column: "petition_id", on_delete: :cascade
  add_foreign_key "archived_rejections", "rejection_reasons", column: "code", primary_key: "code"
  add_foreign_key "archived_signatures", "archived_petitions", column: "petition_id", on_delete: :cascade
  add_foreign_key "constituencies", "regions", primary_key: "external_id"
  add_foreign_key "constituency_petition_journals", "petitions", on_delete: :cascade
  add_foreign_key "debate_outcomes", "petitions", on_delete: :cascade
  add_foreign_key "domains", "domains", column: "canonical_domain_id"
  add_foreign_key "email_requested_receipts", "petitions"
  add_foreign_key "government_responses", "petitions", on_delete: :cascade
  add_foreign_key "notes", "petitions", on_delete: :cascade
  add_foreign_key "parliament_constituencies", "constituencies", primary_key: "external_id"
  add_foreign_key "parliament_constituencies", "parliaments"
  add_foreign_key "petition_emails", "petitions", on_delete: :cascade
  add_foreign_key "petition_mailshots", "petitions"
  add_foreign_key "petition_statistics", "petitions"
  add_foreign_key "petitions", "admin_users", column: "moderated_by_id"
  add_foreign_key "rejections", "petitions", on_delete: :cascade
  add_foreign_key "rejections", "rejection_reasons", column: "code", primary_key: "code"
  add_foreign_key "signatures", "petitions", on_delete: :cascade
  add_foreign_key "trending_domains", "petitions"
  add_foreign_key "trending_ips", "petitions"
end
