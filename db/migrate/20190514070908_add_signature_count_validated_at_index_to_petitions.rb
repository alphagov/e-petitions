class AddSignatureCountValidatedAtIndexToPetitions < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    unless index_exists?("index_petitions_on_validated_at_and_signed_at")
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_petitions_on_validated_at_and_signed_at
        ON petitions USING btree ((last_signed_at > signature_count_validated_at));
      SQL
    end
  end

  def down
    if index_exists?("index_petitions_on_validated_at_and_signed_at")
      execute "DROP INDEX index_petitions_on_validated_at_and_signed_at;"
    end
  end

  private

  def index_exists?(name)
    select_value("SELECT to_regclass('#{name}')")
  end
end
