class BackfillArchivedPetitionPublishedAt < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    up_only do
      execute <<~SQL
        UPDATE archived_petitions
        SET published_at = GREATEST(opened_at, rejected_at)
        WHERE opened_at IS NOT NULL OR rejected_at IS NOT NULL
      SQL
    end
  end
end
