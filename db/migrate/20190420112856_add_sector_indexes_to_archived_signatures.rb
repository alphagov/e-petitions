class AddSectorIndexesToArchivedSignatures < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:archived_signatures, [:sector, :petition_id])
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_archived_signatures_on_sector_and_petition_id
        ON archived_signatures USING btree (LEFT(postcode, -3), petition_id);
      SQL
    end

    unless index_exists?(:archived_signatures, [:sector, :state, :petition_id])
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_archived_signatures_on_sector_and_state_and_petition_id
        ON archived_signatures USING btree (LEFT(postcode, -3), state, petition_id);
      SQL
    end
  end

  def down
    if index_exists?(:archived_signatures, [:sector, :state, :petition_id])
      remove_index :archived_signatures, [:sector, :state, :petition_id]
    end

    if index_exists?(:archived_signatures, [:sector, :petition_id])
      remove_index :archived_signatures, [:sector, :petition_id]
    end
  end

  private

  def index_exists?(table, names)
    select_value("SELECT to_regclass('index_#{table}_on_#{Array(names).join('_and_')}')")
  end
end
