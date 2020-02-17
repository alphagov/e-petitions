# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_02_20_152332) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "intarray"
  enable_extension "plpgsql"

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

  create_table "constituencies", id: :serial, force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "slug", limit: 100, null: false
    t.string "external_id", limit: 30, null: false
    t.string "ons_code", limit: 10, null: false
    t.string "mp_id", limit: 30
    t.string "mp_name", limit: 100
    t.date "mp_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "example_postcode", limit: 30
    t.string "party", limit: 100
    t.index ["external_id"], name: "index_constituencies_on_external_id", unique: true
    t.index ["slug"], name: "index_constituencies_on_slug", unique: true
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

  create_table "contacts", force: :cascade do |t|
    t.bigint "signature_id", null: false
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
    t.string "transcript_url", limit: 500
    t.string "video_url", limit: 500
    t.text "overview"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "debated", default: true, null: false
    t.string "commons_image_file_name"
    t.string "commons_image_content_type"
    t.integer "commons_image_file_size"
    t.datetime "commons_image_updated_at"
    t.string "debate_pack_url", limit: 500
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
    t.datetime "government_response"
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
  end

  create_table "government_responses", id: :serial, force: :cascade do |t|
    t.integer "petition_id"
    t.string "summary", limit: 500, null: false
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "responded_on"
    t.index ["petition_id"], name: "index_government_responses_on_petition_id", unique: true
    t.index ["updated_at"], name: "index_government_responses_on_updated_at"
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
    t.string "ip_address", limit: 20
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

  create_table "languages", force: :cascade do |t|
    t.string "locale", limit: 10, null: false
    t.string "name", limit: 30, null: false
    t.jsonb "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_languages_on_locale", unique: true
    t.index ["name"], name: "index_languages_on_name", unique: true
  end

  create_table "locations", id: :serial, force: :cascade do |t|
    t.string "code", limit: 30, null: false
    t.string "name", limit: 100, null: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["code"], name: "index_locations_on_code", unique: true
    t.index ["name"], name: "index_locations_on_name", unique: true
    t.index ["start_date", "end_date"], name: "index_locations_on_start_date_and_end_date"
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
    t.string "subject", null: false
    t.text "body"
    t.string "sent_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "action", limit: 255, null: false
    t.text "additional_details"
    t.string "state", limit: 10, default: "pending", null: false
    t.datetime "open_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "closed_at"
    t.integer "signature_count", default: 0
    t.boolean "notified_by_email", default: false
    t.string "background", limit: 500
    t.string "sponsor_token", limit: 255
    t.datetime "government_response_at"
    t.date "scheduled_debate_date"
    t.datetime "last_signed_at"
    t.datetime "response_threshold_reached_at"
    t.datetime "debate_threshold_reached_at"
    t.datetime "rejected_at"
    t.datetime "debate_outcome_at"
    t.datetime "moderation_threshold_reached_at"
    t.string "debate_state", limit: 30, default: "pending"
    t.datetime "stopped_at"
    t.boolean "special_consideration"
    t.integer "tags", default: [], null: false, array: true
    t.datetime "locked_at"
    t.integer "locked_by_id"
    t.integer "moderation_lag"
    t.datetime "signature_count_reset_at"
    t.datetime "signature_count_validated_at"
    t.text "committee_note"
    t.index "((last_signed_at > signature_count_validated_at))", name: "index_petitions_on_validated_at_and_signed_at"
    t.index "to_tsvector('english'::regconfig, (action)::text)", name: "index_petitions_on_action", using: :gin
    t.index "to_tsvector('english'::regconfig, (background)::text)", name: "index_petitions_on_background", using: :gin
    t.index "to_tsvector('english'::regconfig, additional_details)", name: "index_petitions_on_additional_details", using: :gin
    t.index ["created_at", "state"], name: "index_petitions_on_created_at_and_state"
    t.index ["debate_state"], name: "index_petitions_on_debate_state"
    t.index ["debate_threshold_reached_at"], name: "index_petitions_on_debate_threshold_reached_at"
    t.index ["last_signed_at"], name: "index_petitions_on_last_signed_at"
    t.index ["locked_by_id"], name: "index_petitions_on_locked_by_id"
    t.index ["moderation_threshold_reached_at", "moderation_lag"], name: "index_petitions_on_mt_reached_at_and_moderation_lag"
    t.index ["response_threshold_reached_at"], name: "index_petitions_on_response_threshold_reached_at"
    t.index ["signature_count", "state"], name: "index_petitions_on_signature_count_and_state"
    t.index ["tags"], name: "index_petitions_on_tags", opclass: :gin__int_ops, using: :gin
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
  end

  create_table "rejections", id: :serial, force: :cascade do |t|
    t.integer "petition_id"
    t.string "code", limit: 50, null: false
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["petition_id"], name: "index_rejections_on_petition_id", unique: true
  end

  create_table "signatures", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "state", limit: 20, default: "pending", null: false
    t.string "perishable_token", limit: 255
    t.string "postcode", limit: 255
    t.string "ip_address", limit: 20
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
    t.datetime "government_response_email_at"
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
    t.index "((ip_address)::inet)", name: "index_signatures_on_inet"
    t.index "((regexp_replace(\"left\"((email)::text, (\"position\"((email)::text, '@'::text) - 1)), '\\.|\\+.+'::text, ''::text, 'g'::text) || \"substring\"((email)::text, \"position\"((email)::text, '@'::text))))", name: "index_signatures_on_normalized_email"
    t.index "\"left\"((postcode)::text, '-3'::integer), petition_id", name: "index_signatures_on_sector_and_petition_id"
    t.index "\"left\"((postcode)::text, '-3'::integer), state, petition_id", name: "index_signatures_on_sector_and_state_and_petition_id"
    t.index "\"substring\"((email)::text, (\"position\"((email)::text, '@'::text) + 1))", name: "index_signatures_on_domain"
    t.index "lower((name)::text)", name: "index_signatures_on_name"
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
    t.string "title_en", limit: 50, default: "Petition parliament", null: false
    t.string "url_en", limit: 50, default: "https://petition.senedd.wales", null: false
    t.string "email_from_en", limit: 100, default: "\"Petitions: Welsh Parliament\" <no-reply@petition.senedd.wales>", null: false
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
    t.datetime "last_checked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "feedback_email", limit: 100, default: "\"Petitions: Welsh Parliament\" <petitionscommittee@senedd.wales>", null: false
    t.string "moderate_url", limit: 50, default: "https://moderate.petition.senedd.wales", null: false
    t.datetime "last_petition_created_at"
    t.integer "login_timeout", default: 1800, null: false
    t.jsonb "feature_flags", default: {}, null: false
    t.datetime "signature_count_updated_at"
    t.integer "signature_count_interval", default: 60, null: false
    t.boolean "update_signature_counts", default: false, null: false
    t.integer "threshold_for_moderation_delay", default: 500, null: false
    t.string "title_cy", limit: 50, default: "Senedd ddeiseb", null: false
    t.string "url_cy", limit: 50, default: "https://deiseb.senedd.cymru", null: false
    t.string "email_from_cy", limit: 100, default: "\"Deisebau: Senedd Cymru\" <dim-ateb@deiseb.senedd.cymru>", null: false
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

  add_foreign_key "constituency_petition_journals", "petitions", on_delete: :cascade
  add_foreign_key "contacts", "signatures", on_delete: :cascade
  add_foreign_key "debate_outcomes", "petitions", on_delete: :cascade
  add_foreign_key "domains", "domains", column: "canonical_domain_id"
  add_foreign_key "email_requested_receipts", "petitions"
  add_foreign_key "government_responses", "petitions", on_delete: :cascade
  add_foreign_key "notes", "petitions", on_delete: :cascade
  add_foreign_key "petition_emails", "petitions", on_delete: :cascade
  add_foreign_key "petition_statistics", "petitions"
  add_foreign_key "rejections", "petitions", on_delete: :cascade
  add_foreign_key "signatures", "petitions", on_delete: :cascade
  add_foreign_key "trending_domains", "petitions"
  add_foreign_key "trending_ips", "petitions"
end
