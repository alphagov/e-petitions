class AddIndexOnFormTokenToSignatures < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, :form_token)
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_signatures_on_form_token
        ON signatures USING btree (form_token);
      SQL
    end
  end

  def down
    if index_exists?(:signatures, :form_token)
      remove_index :signatures, :form_token
    end
  end

  private

  def index_exists?(table, names)
    select_value("SELECT to_regclass('index_#{table}_on_#{Array(names).join('_and_')}')")
  end
end
