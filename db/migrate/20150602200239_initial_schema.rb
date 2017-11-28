class InitialSchema < ActiveRecord::Migration[4.2]
  def change
    create_table :admin_users do |t|
      t.string   :email, limit: 255, null: false
      t.string   :persistence_token, limit: 255
      t.string   :crypted_password, limit: 255
      t.string   :password_salt, limit: 255
      t.integer  :login_count, default: 0
      t.integer  :failed_login_count, default: 0
      t.datetime :current_login_at
      t.datetime :last_login_at
      t.string   :current_login_ip, limit: 255
      t.string   :last_login_ip, limit: 255
      t.string   :first_name, limit: 255
      t.string   :last_name, limit: 255
      t.string   :role, limit: 10, null: false
      t.boolean  :force_password_reset, default: true
      t.datetime :password_changed_at
      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :admin_users, [:email], unique: true
    add_index :admin_users, [:last_name, :first_name]

    create_table :archived_petitions do |t|
      t.string   :title, limit: 255, null: false
      t.text     :description
      t.text     :response
      t.string   :state, limit: 10, default: "open", null: false
      t.text     :reason_for_rejection
      t.datetime :opened_at
      t.datetime :closed_at
      t.integer  :signature_count, default: 0
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    create_table :delayed_jobs do |t|
      t.integer  :priority, default: 0
      t.integer  :attempts, default: 0
      t.text     :handler
      t.text     :last_error
      t.datetime :run_at
      t.datetime :locked_at
      t.datetime :failed_at
      t.string   :locked_by, limit: 255
      t.datetime :created_at
      t.datetime :updated_at
      t.string   :queue, limit: 255
    end

    add_index :delayed_jobs, [:priority, :run_at]

    create_table :petitions do |t|
      t.string   :title, limit: 255, null: false
      t.text     :description
      t.text     :response
      t.string   :state, limit: 10, default: "pending", null: false
      t.datetime :open_at
      t.integer  :creator_signature_id, null: false
      t.datetime :created_at
      t.datetime :updated_at
      t.text     :rejection_text
      t.datetime :closed_at
      t.integer  :signature_count, default: 0
      t.boolean  :response_required, default: false
      t.text     :internal_response
      t.string   :rejection_code, limit: 50
      t.boolean  :notified_by_email, default: false
      t.datetime :email_requested_at
      t.string   :action, limit: 200
      t.string   :sponsor_token, limit: 255
    end

    add_index :petitions, [:creator_signature_id], unique: true
    add_index :petitions, [:response_required, :signature_count]
    add_index :petitions, [:state, :created_at]
    add_index :petitions, [:state, :signature_count]

    create_table :signatures do |t|
      t.string   :name, limit: 255, null: false
      t.string   :state, limit: 10, default: "pending", null: false
      t.string   :perishable_token, limit: 255
      t.string   :postcode, limit: 255
      t.string   :country, limit: 255
      t.string   :ip_address, limit: 20
      t.integer  :petition_id
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean  :notify_by_email, default: true
      t.datetime :last_emailed_at
      t.string   :email, limit: 255
      t.string   :unsubscribe_token
    end

    add_index :signatures, [:email, :petition_id, :name], unique: true
    add_index :signatures, [:petition_id, :state, :name]
    add_index :signatures, [:petition_id, :state]
    add_index :signatures, [:petition_id]
    add_index :signatures, [:state]
    add_index :signatures, [:updated_at]

    create_table :sponsors do |t|
      t.integer  :petition_id
      t.integer  :signature_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    create_table :system_settings do |t|
      t.string   :key, limit: 64, null: false
      t.text     :value
      t.text     :description
      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :system_settings, [:key], unique: true
  end
end
