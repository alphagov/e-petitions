class BackfillPetitionResponseState < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    up_only do
      execute <<~SQL
        UPDATE petitions
        SET response_state = CASE
        WHEN government_response_at IS NOT NULL THEN 'responded'
        WHEN response_threshold_reached_at IS NOT NULL THEN 'awaiting'
        ELSE 'pending'
        END
      SQL
    end
  end
end
