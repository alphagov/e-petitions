class AddTagsToPetitions < ActiveRecord::Migration
  def up
    add_column :petitions, :tags, :string, array: true, default: '{}'
    add_column :archived_petitions, :tags, :string, array: true, default: '{}'

    execute <<-SQL
      CREATE OR REPLACE FUNCTION array_lowercase(varchar[]) RETURNS varchar[] AS
      $BODY$
        SELECT array_agg(q.tag) FROM (
          SELECT btrim(lower(unnest($1)))::varchar AS tag
        ) AS q;
      $BODY$
        language sql IMMUTABLE;

      CREATE INDEX petitions_tag_lower ON petitions USING GIN(array_lowercase(tags));
      CREATE INDEX archived_petitions_tag_lower ON archived_petitions USING GIN(array_lowercase(tags));
    SQL
  end

  def down
    remove_column :petitions, :tags
    remove_column :archived_petitions, :tags

    execute <<-SQL
      DROP INDEX IF EXISTS petitions_tag_lower
      DROP INDEX IF EXISTS archived_petitions_tag_lower
      DROP FUNCTION IF EXISTS array_lowercase
    SQL
  end
end
