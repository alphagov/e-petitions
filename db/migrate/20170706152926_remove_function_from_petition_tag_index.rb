class RemoveFunctionFromPetitionTagIndex < ActiveRecord::Migration
  def up
    remove_index :petitions, name: :petitions_tag_lower
    remove_index :archived_petitions, name: :archived_petitions_tag_lower

    add_index :petitions, :tags, using: :gin
    add_index :archived_petitions, :tags, using: :gin
  end

  def down
    remove_index :petitions, :tags
    remove_index :archived_petitions, :tags

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
end
