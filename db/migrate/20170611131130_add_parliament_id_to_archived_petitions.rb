class AddParliamentIdToArchivedPetitions < ActiveRecord::Migration[4.2]
  class Parliament < ActiveRecord::Base; end
  class ArchivedPetition < ActiveRecord::Base; end

  def up
    add_column :archived_petitions, :parliament_id, :integer
    add_index :archived_petitions, :parliament_id
    add_foreign_key :archived_petitions, :parliaments

    Parliament.reset_column_information
    ArchivedPetition.reset_column_information

    parliament = Parliament.create!(
      government: "Conservative – Liberal Democrat coalition",
      opening_at: "2010-05-18T00:00:00".in_time_zone,
      dissolution_at: "2015-03-30T23:59:59".in_time_zone,
      archived_at: "2015-07-20T00:00:00".in_time_zone
    )

    ArchivedPetition.update_all(parliament_id: parliament.id)
  end

  def down
    remove_foreign_key :archived_petitions, :parliaments
    remove_column :archived_petitions, :parliament_id

    parliament = Parliament.find_by!(opening_at: "2010-05-18T00:00:00".in_time_zone)
    parliament.destroy
  end
end
