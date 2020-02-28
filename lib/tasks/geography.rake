require 'csv'

namespace :wpets do
  namespace :geography do
    desc "Load constituency, postcode and region data"
    task import: :environment do
      region = Class.new(ActiveRecord::Base) { self.table_name = "regions" }
      file = Rails.root.join("data", "regions.json")

      JSON.parse(file.read).each do |row|
        region.create!(row)
      end

      constituency = Class.new(ActiveRecord::Base) { self.table_name = "constituencies" }
      file = Rails.root.join("data", "constituencies.json")

      JSON.parse(file.read).each do |row|
        constituency.create!(row)
      end

      postcode = Class.new(ActiveRecord::Base) { self.table_name = "postcodes" }
      file = Rails.root.join("data", "postcodes.csv")

      CSV.foreach(file, headers: true) do |row|
        postcode.create!(row.to_h)
      end
    end
  end
end
