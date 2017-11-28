class AddPetitionDurationToParliament < ActiveRecord::Migration[4.2]
  class Parliament < ActiveRecord::Base; end

  def up
    add_column :parliaments, :petition_duration, :integer, null: false, default: 6

    parliament = Parliament.find_by!(opening_at: "2010-05-18T00:00:00".in_time_zone)
    parliament.update(petition_duration: 12)
  end

  def down
    remove_column :parliaments, :petition_duration
  end
end
