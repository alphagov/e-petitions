class AdjustPetitionSequences < ActiveRecord::Migration[4.2]
  def up
    execute "ALTER SEQUENCE archived_petitions_id_seq MAXVALUE 99999"
    execute "ALTER SEQUENCE petitions_id_seq START WITH 100000 RESTART WITH 100000 MINVALUE 100000"
  end

  def down
    execute "ALTER SEQUENCE archived_petitions_id_seq NO MAXVALUE"
    execute "ALTER SEQUENCE petitions_id_seq START WITH 1 RESTART WITH 1 NO MINVALUE"
  end
end
