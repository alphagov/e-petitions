class AddIndexToSignatureName < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, :name)
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_signatures_on_name
        ON signatures USING btree ((lower(name)));
      SQL
    end
  end

  def down
    if index_exists?(:signatures, :name)
      remove_index :signatures, :name
    end
  end

  private

  def index_exists?(table, names)
    select_value("SELECT to_regclass('index_#{table}_on_#{Array(names).join('_and_')}')")
  end
end
