require 'csv'

namespace :wpets do
  namespace :geography do
    desc "Load constituency, postcode and region data"
    task import: :environment do
      Rake::Task["wpets:geography:update_regions"].invoke
      Rake::Task["wpets:geography:update_constituencies"].invoke
      Rake::Task["wpets:geography:update_postcodes"].invoke
    end

    task update_constituencies: :environment do
      # Have to drop down to SQL to handle the timestamps
      conn = ActiveRecord::Base.connection.raw_connection

      conn.exec <<~SQL
        CREATE TEMPORARY TABLE constituencies_import (
          id character varying(9) PRIMARY KEY,
          region_id character varying(9) NOT NULL,
          name_en character varying(100) NOT NULL,
          name_cy character varying(100) NOT NULL,
          example_postcode character varying(7) NOT NULL,
          population integer NOT NULL,
          boundary geography(Geometry,4326)
        );
      SQL

      conn.copy_data "COPY constituencies_import FROM STDIN CSV HEADER" do
        file = Rails.root.join("data", "constituencies.csv")

        File.foreach(file) do |line|
          conn.put_copy_data line
        end
      end

      conn.exec <<~SQL
        INSERT INTO constituencies (
          id, region_id, name_en, name_cy,
          example_postcode, population, boundary,
          created_at, updated_at
        )
        SELECT
          id, region_id, name_en, name_cy,
          example_postcode, population, boundary,
          now() AS created_at, now() AS updated_at
        FROM constituencies_import
        ON CONFLICT (id) DO UPDATE
        SET
          region_id = EXCLUDED.region_id,
          name_en = EXCLUDED.name_en,
          name_cy = EXCLUDED.name_cy,
          example_postcode = EXCLUDED.example_postcode,
          population = EXCLUDED.population,
          boundary = EXCLUDED.boundary,
          updated_at = EXCLUDED.updated_at
      SQL

      conn.exec "DROP TABLE constituencies_import"
    end

    task update_regions: :environment do
      # Have to drop down to SQL to handle the timestamps
      conn = ActiveRecord::Base.connection.raw_connection

      conn.exec <<~SQL
        CREATE TEMPORARY TABLE regions_import (
          id character varying(9) PRIMARY KEY,
          name_en character varying(100) NOT NULL,
          name_cy character varying(100) NOT NULL,
          population integer NOT NULL,
          boundary geography(Geometry,4326)
        );
      SQL

      conn.copy_data "COPY regions_import FROM STDIN CSV HEADER" do
        file = Rails.root.join("data", "regions.csv")

        File.foreach(file) do |line|
          conn.put_copy_data line
        end
      end

      conn.exec <<~SQL
        INSERT INTO regions (
          id, name_en, name_cy, population, boundary,
          created_at, updated_at
        )
        SELECT
          id, name_en, name_cy, population, boundary,
          now() AS created_at, now() AS updated_at
        FROM regions_import
        ON CONFLICT (id) DO UPDATE
        SET
          name_en = EXCLUDED.name_en,
          name_cy = EXCLUDED.name_cy,
          population = EXCLUDED.population,
          boundary = EXCLUDED.boundary,
          updated_at = EXCLUDED.updated_at
      SQL

      conn.exec "DROP TABLE regions_import"
    end

    task update_postcodes: :environment do
      # Use the underlying pg gem in a more efficient manner to update postcodes
      conn = ActiveRecord::Base.connection.raw_connection

      conn.exec <<~SQL
        CREATE TEMPORARY TABLE postcodes_import (
          id character varying(7) PRIMARY KEY,
          constituency_id character varying(9) NOT NULL
        );
      SQL

      conn.copy_data "COPY postcodes_import FROM STDIN CSV HEADER" do
        file = Rails.root.join("data", "postcodes.csv")

        File.foreach(file) do |line|
          conn.put_copy_data line
        end
      end

      conn.exec <<~SQL
        INSERT INTO postcodes (id, constituency_id)
        SELECT id, constituency_id
        FROM postcodes_import
        ON CONFLICT (id) DO UPDATE
        SET constituency_id = EXCLUDED.constituency_id
      SQL

      conn.exec "DROP TABLE postcodes_import"
    end
  end
end
