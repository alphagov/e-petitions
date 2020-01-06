class AddTextIndexesToTags < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE INDEX index_ft_tags_on_name ON tags
      USING gin(to_tsvector('english', name));
    SQL

    execute <<-SQL
      CREATE INDEX index_ft_tags_on_description ON tags
      USING gin(to_tsvector('english', description));
    SQL
  end

  def down
    execute "DROP INDEX index_ft_tags_on_name;"
    execute "DROP INDEX index_ft_tags_on_description;"
  end
end
