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

ActiveRecord::Schema.define(version: 2022_03_17_102801) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "intarray"
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
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
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255, null: false
    t.string "persistence_token", limit: 255
    t.string "crypted_password", limit: 255
    t.string "password_salt", limit: 255
    t.integer "login_count", default: 0
    t.integer "failed_login_count", default: 0
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string "current_login_ip", limit: 255
    t.string "last_login_ip", limit: 255
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "role", limit: 10, null: false
    t.boolean "force_password_reset", default: true
    t.datetime "password_changed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_request_at"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["last_name", "first_name"], name: "index_admin_users_on_last_name_and_first_name"
  end

  create_table "constituencies", id: { type: :string, limit: 9 }, force: :cascade do |t|
    t.string "region_id", limit: 9, null: false
    t.string "name_en", limit: 100, null: false
    t.string "name_cy", limit: 100, null: false
    t.string "example_postcode", limit: 7, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.geography "boundary", limit: {:srid=>4326, :type=>"geometry", :geographic=>true}
    t.integer "population", null: false
    t.index ["name_cy"], name: "index_constituencies_on_name_cy", unique: true
    t.index ["name_en"], name: "index_constituencies_on_name_en", unique: true
    t.index ["region_id"], name: "index_constituencies_on_region_id"
  end

  create_table "constituency_petition_journals", id: :serial, force: :cascade do |t|
    t.string "constituency_id", null: false
    t.integer "petition_id", null: false
    t.integer "signature_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_signed_at"
    t.index ["petition_id", "constituency_id"], name: "idx_constituency_petition_journal_uniqueness", unique: true
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.integer "signature_id", null: false
    t.string "address"
    t.string "phone_number", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["signature_id"], name: "index_contacts_on_signature_id"
  end

  create_table "country_petition_journals", id: :serial, force: :cascade do |t|
    t.integer "petition_id", null: false
    t.integer "signature_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location_code", limit: 30
    t.datetime "last_signed_at"
    t.index ["petition_id", "location_code"], name: "index_country_petition_journals_on_petition_and_location", unique: true
  end

  create_table "debate_outcomes", id: :serial, force: :cascade do |t|
    t.integer "petition_id", null: false
    t.date "debated_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "debated", default: true, null: false
    t.string "commons_image_file_name"
    t.string "commons_image_content_type"
    t.integer "commons_image_file_size"
    t.datetime "commons_image_updated_at"
    t.string "transcript_url_en", limit: 500
    t.string "transcript_url_cy", limit: 500
    t.string "video_url_en", limit: 500
    t.string "video_url_cy", limit: 500
    t.string "debate_pack_url_en", limit: 500
    t.string "debate_pack_url_cy", limit: 500
    t.text "overview_en"
    t.text "overview_cy"
    t.index ["petition_id", "debated_on"], name: "index_debate_outcomes_on_petition_id_and_debated_on"
    t.index ["petition_id"], name: "index_debate_outcomes_on_petition_id", unique: true
    t.index ["updated_at"], name: "index_debate_outcomes_on_updated_at"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler"
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "queue", limit: 255
    t.index ["priority", "run_at"], name: "index_delayed_jobs_on_priority_and_run_at"
  end

  create_table "domains", id: :serial, force: :cascade do |t|
    t.integer "canonical_domain_id"
    t.string "name", limit: 100, null: false
    t.string "strip_characters", limit: 10
    t.string "strip_extension", limit: 10, default: "+"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canonical_domain_id"], name: "index_domains_on_canonical_domain_id"
    t.index ["name"], name: "index_domains_on_name", unique: true
  end

  create_table "email_requested_receipts", id: :serial, force: :cascade do |t|
    t.integer "petition_id"
    t.datetime "debate_outcome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "debate_scheduled"
    t.datetime "petition_email"
    t.index ["petition_id"], name: "index_email_requested_receipts_on_petition_id"
  end

  create_table "feedback", id: :serial, force: :cascade do |t|
    t.string "comment", limit: 32768, null: false
    t.string "petition_link_or_title"
    t.string "email"
    t.string "user_agent"
    t.string "ip_address", limit: 40
    t.datetime "created_at"
    t.index ["ip_address"], name: "index_feedback_on_ip_address"
  end

  create_table "holidays", id: :serial, force: :cascade do |t|
    t.date "christmas_start"
    t.date "christmas_end"
    t.date "easter_start"
    t.date "easter_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invalidations", id: :serial, force: :cascade do |t|
    t.string "summary", limit: 255, null: false
    t.string "details", limit: 10000
    t.integer "petition_id"
    t.string "name", limit: 255
    t.string "postcode", limit: 255
    t.string "ip_address", limit: 40
    t.string "email", limit: 255
    t.datetime "created_after"
    t.datetime "created_before"
    t.string "constituency_id", limit: 30
    t.string "location_code", limit: 30
    t.integer "matching_count", default: 0, null: false
    t.integer "invalidated_count", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "started_at"
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "counted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "languages", id: :serial, force: :cascade do |t|
    t.string "locale", limit: 10, null: false
    t.string "name", limit: 30, null: false
    t.jsonb "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_languages_on_locale", unique: true
    t.index ["name"], name: "index_languages_on_name", unique: true
  end

  create_table "members", id: :serial, force: :cascade do |t|
    t.string "region_id", limit: 9
    t.string "constituency_id", limit: 9
    t.string "name_en", limit: 100, null: false
    t.string "name_cy", limit: 100, null: false
    t.string "party_en", limit: 100, null: false
    t.string "party_cy", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["constituency_id"], name: "index_members_on_constituency_id", unique: true
    t.index ["region_id"], name: "index_members_on_region_id"
  end

  create_table "notes", id: :serial, force: :cascade do |t|
    t.integer "petition_id"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["petition_id"], name: "index_notes_on_petition_id", unique: true
  end

  create_table "petition_emails", id: :serial, force: :cascade do |t|
    t.integer "petition_id"
    t.string "sent_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subject_en", null: false
    t.string "subject_cy", null: false
    t.text "body_en"
    t.text "body_cy"
    t.index ["petition_id"], name: "index_petition_emails_on_petition_id"
  end

  create_table "petition_statistics", id: :serial, force: :cascade do |t|
    t.integer "petition_id"
    t.datetime "refreshed_at"
    t.integer "duplicate_emails"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal "pending_rate"
    t.index ["petition_id"], name: "index_petition_statistics_on_petition_id", unique: true
  end

  create_table "petitions", id: :serial, force: :cascade do |t|
    t.string "state", limit: 10, default: "pending", null: false
    t.datetime "open_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "closed_at"
    t.integer "signature_count", default: 0
    t.boolean "notified_by_email", default: false
    t.string "sponsor_token", limit: 255
    t.date "scheduled_debate_date"
    t.datetime "last_signed_at"
    t.datetime "referral_threshold_reached_at"
    t.datetime "debate_threshold_reached_at"
    t.datetime "rejected_at"
    t.datetime "debate_outcome_at"
    t.datetime "moderation_threshold_reached_at"
    t.string "debate_state", limit: 30, default: "pending"
    t.boolean "special_consideration"
    t.integer "tags", default: [], null: false, array: true
    t.datetime "locked_at"
    t.integer "locked_by_id"
    t.integer "moderation_lag"
    t.datetime "signature_count_reset_at"
    t.datetime "signature_count_validated_at"
    t.text "committee_note"
    t.string "locale", limit: 7, default: "en-GB", null: false
    t.string "action_en", limit: 255
    t.string "action_cy", limit: 255
    t.text "additional_details_en"
    t.text "additional_details_cy"
    t.string "background_en", limit: 3000
    t.string "background_cy", limit: 3000
    t.datetime "completed_at"
    t.datetime "referred_at"
    t.string "abms_link_en"
    t.string "abms_link_cy"
    t.boolean "submitted_on_paper", default: false, null: false
    t.date "submitted_on"
    t.datetime "archived_at"
    t.boolean "use_markdown", default: false, null: false
    t.datetime "anonymized_at"
    t.integer "topics", default: [], null: false, array: true
    t.integer "moderated_by_id"
    t.integer "threshold_for_referral"
    t.integer "threshold_for_debate"
    t.index "((last_signed_at > signature_count_validated_at))", name: "index_petitions_on_validated_at_and_signed_at"
    t.index "to_tsvector('english'::regconfig, (action_en)::text)", name: "index_petitions_on_action_en", using: :gin
    t.index "to_tsvector('english'::regconfig, (background_en)::text)", name: "index_petitions_on_background_en", using: :gin
    t.index "to_tsvector('english'::regconfig, additional_details_en)", name: "index_petitions_on_additional_details_en", using: :gin
    t.index "to_tsvector('simple'::regconfig, (action_cy)::text)", name: "index_petitions_on_action_cy", using: :gin
    t.index "to_tsvector('simple'::regconfig, (background_cy)::text)", name: "index_petitions_on_background_cy", using: :gin
    t.index "to_tsvector('simple'::regconfig, additional_details_cy)", name: "index_petitions_on_additional_details_cy", using: :gin
    t.index ["anonymized_at"], name: "index_petitions_on_anonymized_at"
    t.index ["archived_at", "state"], name: "index_petitions_on_archived_at_and_state"
    t.index ["closed_at"], name: "index_petitions_on_closed_at", order: :desc
    t.index ["created_at", "state"], name: "index_petitions_on_created_at_and_state"
    t.index ["debate_state"], name: "index_petitions_on_debate_state"
    t.index ["debate_threshold_reached_at"], name: "index_petitions_on_debate_threshold_reached_at"
    t.index ["last_signed_at"], name: "index_petitions_on_last_signed_at"
    t.index ["locked_by_id"], name: "index_petitions_on_locked_by_id"
    t.index ["moderated_by_id"], name: "index_petitions_on_moderated_by_id"
    t.index ["moderation_threshold_reached_at", "moderation_lag"], name: "index_petitions_on_mt_reached_at_and_moderation_lag"
    t.index ["referral_threshold_reached_at"], name: "index_petitions_on_referral_threshold_reached_at"
    t.index ["referred_at", "created_at"], name: "index_petitions_on_referred_at_and_created_at", order: { created_at: :desc }
    t.index ["signature_count", "created_at"], name: "index_petitions_on_signature_count_and_created_at", order: :desc
    t.index ["signature_count", "state"], name: "index_petitions_on_signature_count_and_state"
    t.index ["state", "debate_state"], name: "index_petitions_on_state_and_debate_state"
    t.index ["tags"], name: "index_petitions_on_tags", opclass: :gin__int_ops, using: :gin
    t.index ["topics"], name: "index_petitions_on_topics", opclass: :gin__int_ops, using: :gin
  end

  create_table "postcodes", id: { type: :string, limit: 7 }, force: :cascade do |t|
    t.string "constituency_id", limit: 9, null: false
    t.index ["constituency_id"], name: "index_postcodes_on_constituency_id"
  end

  create_table "rate_limits", id: :serial, force: :cascade do |t|
    t.integer "burst_rate", default: 1, null: false
    t.integer "burst_period", default: 60, null: false
    t.integer "sustained_rate", default: 5, null: false
    t.integer "sustained_period", default: 300, null: false
    t.string "allowed_domains", limit: 10000, default: "", null: false
    t.string "allowed_ips", limit: 10000, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "regions", id: { type: :string, limit: 9 }, force: :cascade do |t|
    t.string "name_en", limit: 100, null: false
    t.string "name_cy", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.geography "boundary", limit: {:srid=>4326, :type=>"geometry", :geographic=>true}
    t.integer "population", null: false
    t.index ["name_cy"], name: "index_regions_on_name_cy", unique: true
    t.index ["name_en"], name: "index_regions_on_name_en", unique: true
  end

  create_table "rejection_reasons", id: :serial, force: :cascade do |t|
    t.string "code", limit: 30, null: false
    t.string "title", limit: 100, null: false
    t.string "description_en", limit: 2000, null: false
    t.string "description_cy", limit: 2000, null: false
    t.boolean "hidden", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_rejection_reasons_on_code", unique: true
    t.index ["title"], name: "index_rejection_reasons_on_title", unique: true
  end

  create_table "rejections", id: :serial, force: :cascade do |t|
    t.integer "petition_id"
    t.string "code", limit: 50, null: false
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "details_en"
    t.text "details_cy"
    t.index ["petition_id"], name: "index_rejections_on_petition_id", unique: true
  end

  create_table "signatures", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "state", limit: 20, default: "pending", null: false
    t.string "perishable_token", limit: 255
    t.string "postcode", limit: 255
    t.string "ip_address", limit: 40
    t.integer "petition_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "notify_by_email", default: false
    t.string "email", limit: 255
    t.string "unsubscribe_token"
    t.string "constituency_id"
    t.datetime "validated_at"
    t.integer "number"
    t.boolean "seen_signed_confirmation_page", default: false, null: false
    t.string "location_code", limit: 30
    t.datetime "invalidated_at"
    t.integer "invalidation_id"
    t.datetime "debate_scheduled_email_at"
    t.datetime "debate_outcome_email_at"
    t.datetime "petition_email_at"
    t.uuid "uuid"
    t.integer "email_count", default: 0, null: false
    t.boolean "sponsor", default: false, null: false
    t.boolean "creator", default: false, null: false
    t.string "signed_token"
    t.string "validated_ip"
    t.string "canonical_email"
    t.string "locale", limit: 10, default: "en-GB", null: false
    t.datetime "anonymized_at"
    t.index "((ip_address)::inet)", name: "index_signatures_on_inet"
    t.index "((regexp_replace(\"left\"(lower((email)::text), (\"position\"((email)::text, '@'::text) - 1)), '\\.|\\+.+'::text, ''::text, 'g'::text) || \"substring\"(lower((email)::text), \"position\"((email)::text, '@'::text))))", name: "index_signatures_on_lower_normalized_email"
    t.index "\"left\"((postcode)::text, '-3'::integer), petition_id", name: "index_signatures_on_sector_and_petition_id"
    t.index "\"left\"((postcode)::text, '-3'::integer), state, petition_id", name: "index_signatures_on_sector_and_state_and_petition_id"
    t.index "\"substring\"((email)::text, (\"position\"((email)::text, '@'::text) + 1))", name: "index_signatures_on_domain"
    t.index "lower((email)::text)", name: "index_signatures_on_lower_email"
    t.index "lower((name)::text)", name: "index_signatures_on_name"
    t.index ["anonymized_at", "petition_id"], name: "index_signatures_on_anonymized_at_and_petition_id"
    t.index ["canonical_email"], name: "index_signatures_on_canonical_email"
    t.index ["constituency_id"], name: "index_signatures_on_constituency_id"
    t.index ["created_at", "ip_address", "petition_id"], name: "index_signatures_on_created_at_and_ip_address_and_petition_id"
    t.index ["email", "petition_id", "name"], name: "index_signatures_on_email_and_petition_id_and_name", unique: true
    t.index ["invalidation_id"], name: "index_signatures_on_invalidation_id"
    t.index ["ip_address", "petition_id"], name: "index_signatures_on_ip_address_and_petition_id"
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

  create_table "sites", id: :serial, force: :cascade do |t|
    t.string "title_en", limit: 50, default: "Petition the Senedd", null: false
    t.string "url_en", limit: 50, default: "https://petitions.senedd.wales", null: false
    t.string "email_from_en", limit: 100, default: "\"Petitions: Senedd\" <no-reply@petitions.senedd.wales>", null: false
    t.string "username", limit: 30
    t.string "password_digest", limit: 60
    t.boolean "enabled", default: true, null: false
    t.boolean "protected", default: false, null: false
    t.integer "petition_duration", default: 6, null: false
    t.integer "minimum_number_of_sponsors", default: 2, null: false
    t.integer "maximum_number_of_sponsors", default: 20, null: false
    t.integer "threshold_for_moderation", default: 2, null: false
    t.integer "threshold_for_referral", default: 250, null: false
    t.integer "threshold_for_debate", default: 5000, null: false
    t.datetime "last_checked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "feedback_email", limit: 100, default: "\"Petitions: Senedd\" <petitions@senedd.wales>", null: false
    t.string "moderate_url", limit: 50, default: "https://moderate.petitions.senedd.wales", null: false
    t.datetime "last_petition_created_at"
    t.integer "login_timeout", default: 1800, null: false
    t.jsonb "feature_flags", default: {}, null: false
    t.datetime "signature_count_updated_at"
    t.integer "signature_count_interval", default: 60, null: false
    t.boolean "update_signature_counts", default: false, null: false
    t.integer "threshold_for_moderation_delay", default: 500, null: false
    t.string "title_cy", limit: 50, default: "Deisebu'r Senedd", null: false
    t.string "url_cy", limit: 50, default: "https://deisebau.senedd.cymru", null: false
    t.string "email_from_cy", limit: 100, default: "\"Deisebau: Senedd\" <dim-ateb@deisebau.senedd.cymru>", null: false
    t.datetime "translations_updated_at"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "description", limit: 200
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "to_tsvector('english'::regconfig, (description)::text)", name: "index_ft_tags_on_description", using: :gin
    t.index "to_tsvector('english'::regconfig, (name)::text)", name: "index_ft_tags_on_name", using: :gin
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tasks", id: :serial, force: :cascade do |t|
    t.string "name", limit: 60, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tasks_on_name", unique: true
  end

  create_table "topics", id: :serial, force: :cascade do |t|
    t.string "code_en", limit: 100, null: false
    t.string "code_cy", limit: 100, null: false
    t.string "name_en", limit: 100, null: false
    t.string "name_cy", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code_cy"], name: "index_topics_on_code_cy", unique: true
    t.index ["code_en"], name: "index_topics_on_code_en", unique: true
    t.index ["name_cy"], name: "index_topics_on_name_cy", unique: true
    t.index ["name_en"], name: "index_topics_on_name_en", unique: true
  end

  create_table "trending_domains", id: :serial, force: :cascade do |t|
    t.integer "petition_id"
    t.string "domain", limit: 100, null: false
    t.integer "count", null: false
    t.datetime "starts_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "count"], name: "index_trending_domains_on_created_at_and_count", order: { count: :desc }
    t.index ["domain", "petition_id"], name: "index_trending_domains_on_domain_and_petition_id"
    t.index ["petition_id"], name: "index_trending_domains_on_petition_id"
  end

  create_table "trending_ips", id: :serial, force: :cascade do |t|
    t.integer "petition_id"
    t.inet "ip_address", null: false
    t.string "country_code", limit: 30, null: false
    t.integer "count", null: false
    t.datetime "starts_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "count"], name: "index_trending_ips_on_created_at_and_count", order: { count: :desc }
    t.index ["ip_address", "petition_id"], name: "index_trending_ips_on_ip_address_and_petition_id"
    t.index ["petition_id"], name: "index_trending_ips_on_petition_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "constituency_petition_journals", "petitions", on_delete: :cascade
  add_foreign_key "contacts", "signatures", on_delete: :cascade
  add_foreign_key "country_petition_journals", "petitions", on_delete: :cascade
  add_foreign_key "debate_outcomes", "petitions", on_delete: :cascade
  add_foreign_key "domains", "domains", column: "canonical_domain_id"
  add_foreign_key "email_requested_receipts", "petitions"
  add_foreign_key "notes", "petitions", on_delete: :cascade
  add_foreign_key "petition_emails", "petitions", on_delete: :cascade
  add_foreign_key "petition_statistics", "petitions"
  add_foreign_key "petitions", "admin_users", column: "moderated_by_id"
  add_foreign_key "rejections", "petitions", on_delete: :cascade
  add_foreign_key "rejections", "rejection_reasons", column: "code", primary_key: "code"
  add_foreign_key "signatures", "petitions", on_delete: :cascade
  add_foreign_key "trending_domains", "petitions"
  add_foreign_key "trending_ips", "petitions"
end
