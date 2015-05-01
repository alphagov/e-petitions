class RemoveSignaturesPreEncryptionTable < ActiveRecord::Migration
  def change
    drop_table :signatures_pre_encryption do |t|
      t.string   "name",             limit: 255,                     null: false
      t.string   "email",            limit: 255,                     null: false
      t.string   "state",            limit: 10,  default: "pending", null: false
      t.string   "perishable_token", limit: 255
      t.string   "postcode",         limit: 255
      t.string   "country",          limit: 255
      t.string   "ip_address",       limit: 20
      t.references  :petition
      t.timestamps
      t.boolean  "notify_by_email",              default: false
      t.datetime "last_emailed_at"

      t.index ["email", "petition_id", "name"], name: "index_signatures_pre_enc_on_email_and_petition_id_and_name", unique: true, using: :btree
      t.index ["petition_id", "email"], name: "index_signatures_pre_enc_on_petition_id_and_email", using: :btree
      t.index ["petition_id", "state", "name"], name: "index_signatures_pre_enc_on_petition_id_and_state_and_name", using: :btree
      t.index ["petition_id", "state"], name: "index_signatures_pre_enc_on_petition_id_and_state", using: :btree
      t.index ["state"], name: "index_signatures_pre_enc_on_state", using: :btree
      t.index ["updated_at"], name: "index_signatures_pre_enc_on_updated_at", using: :btree
    end
  end
end
