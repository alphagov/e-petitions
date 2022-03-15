class AddBoundaryToConstituencies < ActiveRecord::Migration[6.1]
  def change
    add_column :constituencies, :boundary, :geometry, geographic: true
  end
end
