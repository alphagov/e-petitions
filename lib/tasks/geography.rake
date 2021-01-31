require 'csv'

namespace :wpets do
  namespace :geography do
    desc "Load constituency, postcode and region data"
    task import: :environment do
      region = Class.new(ActiveRecord::Base) { self.table_name = "regions" }
      file = Rails.root.join("data", "regions.csv")

      CSV.foreach(file, headers: true).each do |row|
        region.create!(row.to_h)
      end

      constituency = Class.new(ActiveRecord::Base) { self.table_name = "constituencies" }
      file = Rails.root.join("data", "constituencies.csv")

      CSV.foreach(file, headers: true).each do |row|
        constituency.create!(row.to_h)
      end

      # Use the underlying pg gem in a more efficient manner to insert postcodes
      conn = ActiveRecord::Base.connection.raw_connection
      conn.prepare("insert_postcode", "INSERT INTO postcodes VALUES ($1, $2)")

      file = Rails.root.join("data", "postcodes.csv")

      CSV.foreach(file, headers: true) do |row|
        conn.exec_prepared("insert_postcode", row.fields)
      end
    end

    task update_postcodes: :environment do
      # Use the underlying pg gem in a more efficient manner to update postcodes
      conn = ActiveRecord::Base.connection.raw_connection
      conn.prepare "update_postcode", <<~SQL
        INSERT INTO postcodes VALUES ($1, $2)
        ON CONFLICT (id) DO UPDATE
        SET constituency_id = EXCLUDED.constituency_id
      SQL

      file = Rails.root.join("data", "postcodes.csv")

      CSV.foreach(file, headers: true) do |row|
        conn.exec_prepared("update_postcode", row.fields)
      end
    end
  end
end
