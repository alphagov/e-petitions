class AddPostcodeIndexesToSignatures < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, [:postcode, :petition_id])
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_signatures_on_postcode_and_petition_id
        ON signatures USING btree (postcode, petition_id);
      SQL
    end

    unless index_exists?(:signatures, [:postcode, :state, :petition_id])
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_signatures_on_postcode_and_state_and_petition_id
        ON signatures USING btree (postcode, state, petition_id);
      SQL
    end
  end

  def down
    if index_exists?(:signatures, [:postcode, :state, :petition_id])
      remove_index :signatures, [:postcode, :state, :petition_id]
    end

    if index_exists?(:signatures, [:postcode, :petition_id])
      remove_index :signatures, [:postcode, :petition_id]
    end
  end

  private

  def index_exists?(table, names)
    select_value("SELECT to_regclass('index_#{table}_on_#{Array(names).join('_and_')}')")
  end
end
