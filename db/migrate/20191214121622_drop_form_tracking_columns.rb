class DropFormTrackingColumns < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    remove_index :signatures, :form_token

    ActiveRecord::Base.transaction do
      remove_column :signatures, :form_token
      remove_column :signatures, :image_loaded_at
      remove_column :signatures, :form_requested_at
      remove_column :rate_limits, :threshold_for_form_entry
    end
  end

  def down
    ActiveRecord::Base.transaction do
      add_column :rate_limits, :threshold_for_form_entry, :integer, null: false, default: 0
      add_column :signatures, :form_requested_at, :datetime
      add_column :signatures, :image_loaded_at, :datetime
      add_column :signatures, :form_token, :string
    end

    execute <<-SQL
      CREATE INDEX CONCURRENTLY index_signatures_on_form_token
      ON signatures USING btree (form_token);
    SQL
  end
end
