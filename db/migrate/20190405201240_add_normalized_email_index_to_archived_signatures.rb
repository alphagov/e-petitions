class AddNormalizedEmailIndexToArchivedSignatures < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:archived_signatures, :normalized_email)
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_archived_signatures_on_normalized_email
        ON archived_signatures USING btree ((
          REGEXP_REPLACE(LEFT(email, POSITION('@' IN email) - 1), '\.|\+.+', '', 'g') ||
          SUBSTRING(email FROM POSITION('@' IN email))
        ));
      SQL
    end
  end

  def down
    if index_exists?(:archived_signatures, :normalized_email)
      remove_index :archived_signatures, :normalized_email
    end
  end

  private

  def index_exists?(table, names)
    select_value("SELECT to_regclass('index_#{table}_on_#{Array(names).join('_and_')}')")
  end
end
