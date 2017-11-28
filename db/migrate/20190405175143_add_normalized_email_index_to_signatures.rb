class AddNormalizedEmailIndexToSignatures < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, :normalized_email)
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_signatures_on_normalized_email
        ON signatures USING btree ((
          REGEXP_REPLACE(LEFT(email, POSITION('@' IN email) - 1), '\.|\+.+', '', 'g') ||
          SUBSTRING(email FROM POSITION('@' IN email))
        ));
      SQL
    end
  end

  def down
    if index_exists?(:signatures, :normalized_email)
      remove_index :signatures, :normalized_email
    end
  end

  private

  def index_exists?(table, names)
    select_value("SELECT to_regclass('index_#{table}_on_#{Array(names).join('_and_')}')")
  end
end
