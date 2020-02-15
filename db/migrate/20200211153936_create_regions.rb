class CreateRegions < ActiveRecord::Migration[5.2]
  class Region < ActiveRecord::Base; end

  def change
    create_table :regions, id: :serial do |t|
      t.string :external_id, limit: 30, null: false
      t.string :name, limit: 50, null: false
      t.string :ons_code, limit: 10, null: false
      t.timestamps null: false
    end

    add_index :regions, :external_id, unique: true
    add_index :regions, :name, unique: true
    add_index :regions, :ons_code, unique: true

    # Data for this comes from the Parliament OData API:
    # http://data.parliament.uk/membersdataplatform/open/OData.svc/Areas?$select=Area_Id,Name,OnsAreaId&$filter=AreaType_Id+eq+8
    up_only do
      [
        ["107", "North East", "A"],
        ["108", "North West", "B"],
        ["109", "Yorkshire and The Humber", "D"],
        ["110", "East Midlands", "E"],
        ["111", "West Midlands", "F"],
        ["112", "East of England", "G"],
        ["113", "London", "H"],
        ["114", "South East", "J"],
        ["115", "South West", "K"],
        ["116", "Wales", "L"],
        ["117", "Scotland", "M"],
        ["118", "Northern Ireland", "N"]
      ].each do |external_id, name, ons_code|
        Region.create!(external_id: external_id, name: name, ons_code: ons_code)
      end
    end
  end
end
