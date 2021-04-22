class UpdateNormalizedEmailIndexes < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    unless index_exists?(:index_signatures_on_lower_normalized_email)
      execute <<~SQL
        CREATE INDEX CONCURRENTLY index_signatures_on_lower_normalized_email
        ON signatures USING btree ((
          REGEXP_REPLACE(LEFT(LOWER(email), POSITION('@' IN email) - 1), '\\.|\\+.+', '', 'g') ||
          SUBSTRING(LOWER(email) FROM POSITION('@' IN email))
        ));
      SQL
    end

    if index_exists?(:index_signatures_on_normalized_email)
      execute <<~SQL
        DROP INDEX CONCURRENTLY index_signatures_on_normalized_email
      SQL
    end
  end

  def down
    unless index_exists?(:index_signatures_on_normalized_email)
      execute <<~SQL
        CREATE INDEX CONCURRENTLY index_signatures_on_normalized_email
        ON signatures USING btree ((
          REGEXP_REPLACE(LEFT(email, POSITION('@' IN email) - 1), '\\.|\\+.+', '', 'g') ||
          SUBSTRING(email FROM POSITION('@' IN email))
        ));
      SQL
    end

    if index_exists?(:index_signatures_on_lower_normalized_email)
      execute <<~SQL
        DROP INDEX CONCURRENTLY index_signatures_on_lower_normalized_email
      SQL
    end
  end

  private

  def index_exists?(name)
    select_value("SELECT to_regclass('#{name}')::text")
  end
end
