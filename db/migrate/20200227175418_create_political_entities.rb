require 'csv'

class CreatePoliticalEntities < ActiveRecord::Migration[5.2]
  class Region < ActiveRecord::Base; end
  class Constituency < ActiveRecord::Base; end
  class Postcode < ActiveRecord::Base; end

  def change
    create_table :regions, id: false do |t|
      t.primary_key :id, :string, limit: 9
      t.string :name_en, limit: 100, null: false, index: { unique: true }
      t.string :name_cy, limit: 100, null: false, index: { unique: true }
      t.timestamps null: false
    end

    create_table :constituencies, id: false do |t|
      t.primary_key :id, :string, limit: 9
      t.string :region_id, limit: 9, null: false, index: true, foreign_key: true
      t.string :name_en, limit: 100, null: false, index: { unique: true }
      t.string :name_cy, limit: 100, null: false, index: { unique: true }
      t.string :example_postcode, limit: 7, null: false
      t.timestamps null: false
    end

    create_table :members, id: false do |t|
      t.primary_key :id, :integer
      t.string :region_id, limit: 9, index: true, foreign_key: true
      t.string :constituency_id, limit: 9, index: { unique: true }, foreign_key: true
      t.string :name_en, limit: 100, null: false
      t.string :name_cy, limit: 100, null: false
      t.string :party_en, limit: 100, null: false
      t.string :party_cy, limit: 100, null: false
      t.timestamps null: false
    end

    create_table :postcodes, id: false do |t|
      t.primary_key :id, :string, limit: 7
      t.string :constituency_id, limit: 9, null: false, index: true, foreign_key: true
    end

    up_only do
      load_json("regions.json") { |region| Region.create!(region) }
      load_json("constituencies.json") { |constituency| Constituency.create!(constituency) }
      load_csv("postcodes.csv") { |postcode| Postcode.create!(postcode) }
    end
  end

  private

  def load_json(file)
    JSON.parse(data_file(file).read).each { |row| yield row }
  end

  def load_csv(file)
    CSV.foreach(data_file(file), headers: true) { |row| yield row.to_h }
  end

  def data_file(file)
    Rails.root.join("data", file)
  end
end
