class AddLowerIndexToSignaturesEmail < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    unless index_exists?(:index_signatures_on_lower_email)
      execute <<~SQL
        CREATE INDEX CONCURRENTLY index_signatures_on_lower_email
        ON signatures USING btree ((lower(email)));
      SQL
    end
  end

  def down
    if index_exists?(:index_signatures_on_lower_email)
      execute <<~SQL
        DROP INDEX CONCURRENTLY index_signatures_on_lower_email;
      SQL
    end
  end

  private

  def index_exists?(name)
    select_value("SELECT to_regclass('#{name}')::text")
  end
end
