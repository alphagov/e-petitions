class AddInetIndexToArchivedSignatures < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:archived_signatures, :inet)
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_archived_signatures_on_inet
        ON archived_signatures USING btree (inet(ip_address));
      SQL
    end
  end

  def down
    if index_exists?(:archived_signatures, :inet)
      remove_index :archived_signatures, :inet
    end
  end

  private

  def index_exists?(table, names)
    select_value("SELECT to_regclass('index_#{table}_on_#{Array(names).join('_and_')}')")
  end
end
