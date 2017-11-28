class NullifyPreviousParliamentPetitionDuration < ActiveRecord::Migration[4.2]
  class Parliament < ActiveRecord::Base; end

  def up
    change_column_null(:parliaments, :petition_duration, true)

    parliament = Parliament.find_by!(opening_at: "2010-05-18T00:00:00".in_time_zone)
    parliament.update(petition_duration: nil)
  end

  def down
    parliament = Parliament.find_by!(opening_at: "2010-05-18T00:00:00".in_time_zone)
    parliament.update(petition_duration: 12)

    change_column_null(:parliaments, :petition_duration, false)
  end
end
