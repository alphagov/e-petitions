class ReverseAnonymizedAtIndexColumnOrder < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    %i[signatures archived_signatures].each do |table|
      add_index table, %i[petition_id anonymized_at], algorithm: :concurrently, if_not_exists: true
      remove_index table, %i[anonymized_at petition_id], algorithm: :concurrently, if_exists: true
    end
  end

  def down
    %i[signatures archived_signatures].each do |table|
      add_index table, %i[anonymized_at petition_id], algorithm: :concurrently, if_not_exists: true
      remove_index table, %i[petition_id anonymized_at], algorithm: :concurrently, if_exists: true
    end
  end
end
