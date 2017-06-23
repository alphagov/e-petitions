class AddDomainIndexToSignatures < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, :domain)
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_signatures_on_domain
        ON signatures USING btree (SUBSTRING(email FROM POSITION('@' IN email) + 1));
      SQL
    end
  end

  def down
    if index_exists?(:signatures, :domain)
      remove_index :signatures, :domain
    end
  end

  private

  def index_exists?(table, names)
    select_value("SELECT to_regclass('index_#{table}_on_#{Array(names).join('_and_')}')")
  end
end
