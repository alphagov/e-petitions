class AddAnonymizedAtColumns < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    %i[signatures archived_signatures].each do |table|
      unless column_exists?(table, :anonymized_at)
        add_column table, :anonymized_at, :datetime
      end

      unless index_exists?(table, [:anonymized_at, :petition_id])
        add_index table, [:anonymized_at, :petition_id], algorithm: :concurrently
      end
    end

    %i[petitions archived_petitions].each do |table|
      unless column_exists?(table, :anonymized_at)
        add_column table, :anonymized_at, :datetime
      end

      unless index_exists?(table, :anonymized_at)
        add_index table, :anonymized_at, algorithm: :concurrently
      end
    end
  end

  def down
    %i[petitions archived_petitions].each do |table|
      if index_exists?(table, :anonymized_at)
        remove_index table, :anonymized_at
      end

      if column_exists?(table, :anonymized_at)
        remove_column table, :anonymized_at
      end
    end

    %i[signatures archived_signatures].each do |table|
      unless index_exists?(table, [:anonymized_at, :petition_id])
        remove_index table, [:anonymized_at, :petition_id]
      end

      unless column_exists?(table, :anonymized_at)
        remove_column table, :anonymized_at, :datetime
      end
    end
  end
end
