class AddEndDateToConstituencies < ActiveRecord::Migration[7.1]
  def change
    up_only do
      Constituency.update_all(end_date: "2024/05/30")
      FetchConstituenciesJob.perform_now
    end
  end
end