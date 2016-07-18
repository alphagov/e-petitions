class CreateInvalidations < ActiveRecord::Migration
  def change
    create_table :invalidations do |t|
      t.string   :summary, limit: 255, null: false
      t.string   :details, limit: 10000
      t.integer  :petition_id
      t.string   :name, limit: 255
      t.string   :postcode, limit: 255
      t.string   :ip_address, limit: 20
      t.string   :email, limit: 255
      t.datetime :created_after
      t.datetime :created_before
      t.string   :constituency_id, limit: 30
      t.string   :location_code, limit: 30
      t.integer  :matching_count, null: false, default: 0
      t.integer  :invalidated_count, null: false, default: 0
      t.datetime :enqueued_at, null: true
      t.datetime :started_at, null: true
      t.datetime :cancelled_at, null: true
      t.datetime :completed_at, null: true
      t.datetime :counted_at, null: true
      t.timestamps null: false
    end

    add_index :invalidations, :petition_id
    add_index :invalidations, :started_at
    add_index :invalidations, :completed_at
    add_index :invalidations, :cancelled_at
  end
end
