# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150518160218) do

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                limit: 255,                null: false
    t.string   "persistence_token",    limit: 255
    t.string   "crypted_password",     limit: 255
    t.string   "password_salt",        limit: 255
    t.integer  "login_count",          limit: 4,   default: 0
    t.integer  "failed_login_count",   limit: 4,   default: 0
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip",     limit: 255
    t.string   "last_login_ip",        limit: 255
    t.string   "first_name",           limit: 255
    t.string   "last_name",            limit: 255
    t.string   "role",                 limit: 10,                 null: false
    t.boolean  "force_password_reset",             default: true
    t.datetime "password_changed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["last_name", "first_name"], name: "index_admin_users_on_last_name_and_first_name", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0
    t.integer  "attempts",   limit: 4,     default: 0
    t.text     "handler",    limit: 65535
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue",      limit: 255
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "department_assignments", force: :cascade do |t|
    t.integer  "petition_id",   limit: 4
    t.integer  "department_id", limit: 4
    t.datetime "assigned_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "departments", force: :cascade do |t|
    t.string   "name",        limit: 255,   null: false
    t.text     "description", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "website_url", limit: 255
  end

  add_index "departments", ["name"], name: "index_departments_on_name", unique: true, using: :btree

  create_table "petitions", force: :cascade do |t|
    t.string   "title",                   limit: 255,                       null: false
    t.text     "description",             limit: 65535
    t.text     "response",                limit: 65535
    t.string   "state",                   limit: 10,    default: "pending", null: false
    t.datetime "open_at"
    t.integer  "department_id",           limit: 4
    t.integer  "creator_signature_id",    limit: 4,                         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "rejection_text",          limit: 65535
    t.datetime "closed_at"
    t.integer  "signature_count",         limit: 4,     default: 0
    t.boolean  "response_required",                     default: false
    t.text     "internal_response",       limit: 65535
    t.string   "rejection_code",          limit: 50
    t.boolean  "notified_by_email",                     default: false
    t.datetime "email_requested_at"
    t.string   "action",                  limit: 200
  end

  add_index "petitions", ["creator_signature_id"], name: "index_petitions_on_creator_signature_id", unique: true, using: :btree
  add_index "petitions", ["department_id", "state", "closed_at", "signature_count"], name: "petitions_by_sig_count_closed_at", using: :btree
  add_index "petitions", ["department_id", "state", "closed_at", "title"], name: "petitions_by_title_closed_at", using: :btree
  add_index "petitions", ["department_id", "state", "created_at"], name: "index_petitions_on_department_id_and_state_and_created_at", using: :btree
  add_index "petitions", ["department_id", "state", "signature_count"], name: "petitions_by_sig_count", using: :btree
  add_index "petitions", ["department_id", "state", "title"], name: "petitions_by_title", using: :btree
  add_index "petitions", ["response_required", "signature_count"], name: "index_petitions_on_response_required_and_signature_count", using: :btree
  add_index "petitions", ["state", "created_at"], name: "index_petitions_on_state_and_created_at", using: :btree
  add_index "petitions", ["state", "signature_count"], name: "index_petitions_on_state_and_signature_count", using: :btree

  create_table "signatures", force: :cascade do |t|
    t.string   "name",             limit: 255,                     null: false
    t.string   "state",            limit: 10,  default: "pending", null: false
    t.string   "perishable_token", limit: 255
    t.string   "postcode",         limit: 255
    t.string   "country",          limit: 255
    t.string   "ip_address",       limit: 20
    t.integer  "petition_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "notify_by_email",              default: true
    t.datetime "last_emailed_at"
    t.string   "encrypted_email",  limit: 255
  end

  add_index "signatures", ["encrypted_email", "petition_id", "name"], name: "index_signatures_on_encrypted_email_and_petition_id_and_name", unique: true, using: :btree
  add_index "signatures", ["petition_id", "state", "name"], name: "index_signatures_on_petition_id_and_state_and_name", using: :btree
  add_index "signatures", ["petition_id", "state"], name: "index_signatures_on_petition_id_and_state", using: :btree
  add_index "signatures", ["petition_id"], name: "index_signatures_on_petition_id_and_email", using: :btree
  add_index "signatures", ["state"], name: "index_signatures_on_state", using: :btree
  add_index "signatures", ["updated_at"], name: "index_signatures_on_updated_at", using: :btree

  create_table "sponsors", force: :cascade do |t|
    t.string   "encrypted_email",  limit: 255
    t.string   "perishable_token", limit: 255
    t.integer  "petition_id",      limit: 4
    t.integer  "signature_id",     limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "system_settings", force: :cascade do |t|
    t.string   "key",         limit: 64,    null: false
    t.text     "value",       limit: 65535
    t.text     "description", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "system_settings", ["key"], name: "index_system_settings_on_key", unique: true, using: :btree

  create_table "trending_petitions", force: :cascade do |t|
    t.integer  "petition_id",             limit: 4
    t.integer  "signatures_in_last_hour", limit: 4, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
