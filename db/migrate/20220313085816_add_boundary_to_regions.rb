class AddBoundaryToRegions < ActiveRecord::Migration[6.1]
  def change
    add_column :regions, :boundary, :geometry, geographic: true
  end
end
