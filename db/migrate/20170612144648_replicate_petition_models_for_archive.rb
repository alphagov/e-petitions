class ReplicatePetitionModelsForArchive < ActiveRecord::Migration[4.2]
  def change
    create_table :archived_debate_outcomes do |t|
      t.integer  :petition_id, null: false
      t.date     :debated_on
      t.string   :transcript_url, limit: 500
      t.string   :video_url, limit: 500
      t.text     :overview
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.boolean  :debated, default: true, null: false
      t.string   :commons_image_file_name
      t.string   :commons_image_content_type
      t.integer  :commons_image_file_size
      t.datetime :commons_image_updated_at
    end

    add_index :archived_debate_outcomes, [:petition_id, :debated_on]
    add_index :archived_debate_outcomes, :petition_id, unique: true
    add_index :archived_debate_outcomes, :updated_at
    add_foreign_key :archived_debate_outcomes, :archived_petitions, column: :petition_id, on_delete: :cascade

    create_table :archived_government_responses do |t|
      t.integer  :petition_id
      t.string   :summary, limit: 500, null: false
      t.text     :details
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :archived_government_responses, :petition_id, unique: true
    add_index :archived_government_responses, :updated_at
    add_foreign_key :archived_government_responses, :archived_petitions, column: :petition_id, on_delete: :cascade

    create_table :archived_notes do |t|
      t.integer  :petition_id
      t.text     :details
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :archived_notes, :petition_id, unique: true
    add_foreign_key :archived_notes, :archived_petitions, column: :petition_id, on_delete: :cascade

    create_table :archived_petition_emails, force: :cascade do |t|
      t.integer  :petition_id
      t.string   :subject, null: false
      t.text     :body
      t.string   :sent_by
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :archived_petition_emails, :petition_id
    add_foreign_key :archived_petition_emails, :archived_petitions, column: :petition_id, on_delete: :cascade

    create_table :archived_rejections, force: :cascade do |t|
      t.integer  :petition_id
      t.string   :code, limit: 50, null: false
      t.text     :details
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :archived_rejections, :petition_id, unique: true
    add_foreign_key :archived_rejections, :archived_petitions, column: :petition_id, on_delete: :cascade

    create_table :archived_signatures do |t|
      t.string   :name, limit: 255, null: false
      t.string   :state, limit: 20, default: "pending", null: false
      t.string   :perishable_token, limit: 255
      t.string   :postcode, limit: 255
      t.string   :ip_address, limit: 20
      t.integer  :petition_id
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean  :notify_by_email, default: true
      t.string   :email, limit: 255
      t.string   :unsubscribe_token
      t.string   :constituency_id
      t.datetime :validated_at
      t.integer  :number
      t.boolean  :seen_signed_confirmation_page, default: false, null: false
      t.string   :location_code, limit: 30
      t.datetime :invalidated_at
      t.integer  :invalidation_id
      t.datetime :government_response_email_at
      t.datetime :debate_scheduled_email_at
      t.datetime :debate_outcome_email_at
      t.datetime :petition_email_at
      t.uuid     :uuid
      t.boolean  :creator, default: false, null: false
      t.boolean  :sponsor, default: false, null: false
    end

    add_index :archived_signatures, :constituency_id
    add_index :archived_signatures, [:created_at, :ip_address, :petition_id], name: "index_archived_signatures_on_creation_ip_and_petition_id"
    add_index :archived_signatures, [:email, :petition_id, :name], unique: true
    add_index :archived_signatures, :invalidation_id
    add_index :archived_signatures, [:ip_address, :petition_id]
    add_index :archived_signatures, [:petition_id, :location_code]
    add_index :archived_signatures, :petition_id
    add_index :archived_signatures, [:state, :petition_id]
    add_index :archived_signatures, :updated_at
    add_index :archived_signatures, :uuid
    add_index :archived_signatures, :validated_at
    add_index :archived_signatures, [:creator, :petition_id]
    add_index :archived_signatures, [:sponsor, :petition_id]
    add_foreign_key :archived_signatures, :archived_petitions, column: :petition_id, on_delete: :cascade

    add_column :archived_petitions, :action, :string, limit: 255
    add_column :archived_petitions, :background, :string, limit: 300
    add_column :archived_petitions, :additional_details, :text
    add_column :archived_petitions, :government_response_at, :datetime
    add_column :archived_petitions, :scheduled_debate_date, :date
    add_column :archived_petitions, :last_signed_at, :datetime
    add_column :archived_petitions, :response_threshold_reached_at, :datetime
    add_column :archived_petitions, :debate_threshold_reached_at, :datetime
    add_column :archived_petitions, :rejected_at, :datetime
    add_column :archived_petitions, :debate_outcome_at, :datetime
    add_column :archived_petitions, :moderation_threshold_reached_at, :datetime
    add_column :archived_petitions, :debate_state, :string, limit: 30
    add_column :archived_petitions, :stopped_at, :datetime
    add_column :archived_petitions, :special_consideration, :boolean
  end
end
