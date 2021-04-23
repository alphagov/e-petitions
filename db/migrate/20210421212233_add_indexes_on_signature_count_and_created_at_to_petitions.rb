class AddIndexesOnSignatureCountAndCreatedAtToPetitions < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    unless index_exists?(:index_petitions_on_signature_count_and_created_at)
      execute <<~SQL
        CREATE INDEX CONCURRENTLY index_petitions_on_signature_count_and_created_at
        ON petitions (signature_count DESC, created_at DESC);
      SQL
    end
  end

  def down
    if index_exists?(:index_petitions_on_signature_count_and_created_at)
      execute <<~SQL
        DROP INDEX CONCURRENTLY index_petitions_on_signature_count_and_created_at;
      SQL
    end
  end

  private

  def index_exists?(name)
    select_value("SELECT to_regclass('#{name}')::text")
  end
end
