class BackfillPetitionPublishedAt < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    up_only do
      execute <<~SQL
        UPDATE petitions
        SET published_at = GREATEST(open_at, rejected_at)
        WHERE open_at IS NOT NULL OR rejected_at IS NOT NULL
      SQL
    end
  end
end
