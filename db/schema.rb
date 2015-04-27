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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120621155427) do

  create_table "admin_users", :force => true do |t|
    t.string   "email",                                                :null => false
    t.string   "persistence_token"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.integer  "login_count",                        :default => 0
    t.integer  "failed_login_count",                 :default => 0
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "role",                 :limit => 10,                   :null => false
    t.boolean  "force_password_reset",               :default => true
    t.datetime "password_changed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["last_name", "first_name"], :name => "index_admin_users_on_last_name_and_first_name"

  create_table "admin_users_departments", :id => false, :force => true do |t|
    t.integer "admin_user_id", :null => false
    t.integer "department_id", :null => false
  end

  add_index "admin_users_departments", ["admin_user_id", "department_id"], :name => "index_admin_users_departments_on_fks", :unique => true
  add_index "admin_users_departments", ["department_id"], :name => "index_admin_users_departments_on_department_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "department_assignments", :force => true do |t|
    t.integer  "petition_id"
    t.integer  "department_id"
    t.datetime "assigned_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "departments", :force => true do |t|
    t.string   "name",        :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "website_url"
  end

  add_index "departments", ["name"], :name => "index_departments_on_name", :unique => true

  create_table "petitions", :force => true do |t|
    t.string   "title",                                                        :null => false
    t.text     "description"
    t.text     "response"
    t.string   "state",                   :limit => 10, :default => "pending", :null => false
    t.datetime "open_at"
    t.integer  "department_id",                                                :null => false
    t.integer  "creator_signature_id",                                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator_id"
    t.text     "rejection_text"
    t.datetime "closed_at"
    t.integer  "signature_count",                       :default => 0
    t.boolean  "response_required",                     :default => false
    t.text     "internal_response"
    t.string   "rejection_code",          :limit => 50
    t.boolean  "notified_by_email",                     :default => false
    t.string   "duration",                :limit => 2,  :default => "12"
    t.datetime "email_requested_at"
    t.datetime "get_an_mp_email_sent_at"
  end

  add_index "petitions", ["creator_signature_id"], :name => "index_petitions_on_creator_signature_id", :unique => true
  add_index "petitions", ["department_id", "state", "closed_at", "signature_count"], :name => "petitions_by_sig_count_closed_at"
  add_index "petitions", ["department_id", "state", "closed_at", "title"], :name => "petitions_by_title_closed_at"
  add_index "petitions", ["department_id", "state", "created_at"], :name => "index_petitions_on_department_id_and_state_and_created_at"
  add_index "petitions", ["department_id", "state", "signature_count"], :name => "petitions_by_sig_count"
  add_index "petitions", ["department_id", "state", "title"], :name => "petitions_by_title"
  add_index "petitions", ["get_an_mp_email_sent_at"], :name => "index_petitions_on_get_an_mp_email_sent_at"
  add_index "petitions", ["response_required", "signature_count"], :name => "index_petitions_on_response_required_and_signature_count"
  add_index "petitions", ["state", "created_at"], :name => "index_petitions_on_state_and_created_at"
  add_index "petitions", ["state", "signature_count"], :name => "index_petitions_on_state_and_signature_count"

  create_table "signatures", :force => true do |t|
    t.string   "name",                                                  :null => false
    t.string   "state",            :limit => 10, :default => "pending", :null => false
    t.string   "perishable_token"
    t.string   "postcode"
    t.string   "country"
    t.string   "ip_address",       :limit => 20
    t.integer  "petition_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "notify_by_email",                :default => false
    t.datetime "last_emailed_at"
    t.string   "encrypted_email"
  end

  add_index "signatures", ["encrypted_email", "petition_id", "name"], :name => "index_signatures_on_encrypted_email_and_petition_id_and_name", :unique => true
  add_index "signatures", ["petition_id", "state", "name"], :name => "index_signatures_on_petition_id_and_state_and_name"
  add_index "signatures", ["petition_id", "state"], :name => "index_signatures_on_petition_id_and_state"
  add_index "signatures", ["petition_id"], :name => "index_signatures_on_petition_id_and_email"
  add_index "signatures", ["state"], :name => "index_signatures_on_state"
  add_index "signatures", ["updated_at"], :name => "index_signatures_on_updated_at"

  create_table "signatures_pre_encryption", :force => true do |t|
    t.string   "name",                                                  :null => false
    t.string   "email",                                                 :null => false
    t.string   "state",            :limit => 10, :default => "pending", :null => false
    t.string   "perishable_token"
    t.string   "postcode"
    t.string   "country"
    t.string   "ip_address",       :limit => 20
    t.integer  "petition_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "notify_by_email",                :default => false
    t.datetime "last_emailed_at"
  end

  add_index "signatures_pre_encryption", ["email", "petition_id", "name"], :name => "index_signatures_on_email_and_petition_id_and_name", :unique => true
  add_index "signatures_pre_encryption", ["petition_id", "email"], :name => "index_signatures_on_petition_id_and_email"
  add_index "signatures_pre_encryption", ["petition_id", "state", "name"], :name => "index_signatures_on_petition_id_and_state_and_name"
  add_index "signatures_pre_encryption", ["petition_id", "state"], :name => "index_signatures_on_petition_id_and_state"
  add_index "signatures_pre_encryption", ["state"], :name => "index_signatures_on_state"
  add_index "signatures_pre_encryption", ["updated_at"], :name => "index_signatures_on_updated_at"

  create_table "system_settings", :force => true do |t|
    t.string   "key",         :limit => 64, :null => false
    t.text     "value"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "system_settings", ["key"], :name => "index_system_settings_on_key", :unique => true

  create_table "trending_petitions", :force => true do |t|
    t.integer  "petition_id"
    t.integer  "signatures_in_last_hour", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
