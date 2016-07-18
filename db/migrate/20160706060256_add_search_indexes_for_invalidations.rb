class AddSearchIndexesForInvalidations < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE INDEX ft_index_invalidations_on_id ON invalidations
      USING gin(to_tsvector('english', id::text));
    SQL

    execute <<-SQL
      CREATE INDEX ft_index_invalidations_on_summary ON invalidations
      USING gin(to_tsvector('english', summary));
    SQL

    execute <<-SQL
      CREATE INDEX ft_index_invalidations_on_details ON invalidations
      USING gin(to_tsvector('english', details));
    SQL

    execute <<-SQL
      CREATE INDEX ft_index_invalidations_on_petition_id ON invalidations
      USING gin(to_tsvector('english', petition_id::text));
    SQL
  end

  def down
    execute "DROP INDEX ft_index_invalidations_on_id;"
    execute "DROP INDEX ft_index_invalidations_on_summary;"
    execute "DROP INDEX ft_index_invalidations_on_details;"
    execute "DROP INDEX ft_index_invalidations_on_petition_id;"
  end
end
