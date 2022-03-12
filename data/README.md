# Building the geography CSV files

## Requirements

You’ll need to have a recent PostgreSQL and PostGIS version installed on your computer. It is best to create a new empty database in PostgreSQL to carry out the process of building the tables.

## Data sources

1. [Ordnance Survey Boundary-Line™][1]
2. [ONS Postcode Directory][2]
3. [Welsh Output Area to Constituency to Region Lookup][3]

The latest version of the ONS Postcode Directory should be used - it is updated every three months.

## Procedure

First, ensure the PostGIS extension is enabled in your database:

``` sql
CREATE EXTENSION postgis;
```

Next, import the constituency boundary line data use the `ogr2ogr` tool. 

``` sh
ogr2ogr -nlt PROMOTE_TO_MULTI -f "PostgreSQL" PG:"host=localhost dbname=<your-local-database>" scotland_and_wales_const_region.shp
```

Once this is done you should have the table `scotland_and_wales_const_region` in your database. Since the table contain both Scottish and Welsh boundaries we need to filter out the Welsh data. We can do this by creating a view onto the table and for better performance we can create it as a [materialized view][4].

``` sql
CREATE MATERIALIZED VIEW welsh_constituencies AS
SELECT code, REPLACE(name, ' P Const', '') AS name, wkb_geometry AS boundary
FROM scotland_and_wales_const_region
WHERE area_code = 'WPC'
ORDER BY code;
```

The views also do some housekeeping on the names to remove the unnecessary suffixes for our purposes. For performance reasons later also create the following indexes on the `boundary` column so that the PostGIS `st_within` function can use a simple bounding-box calculation to filter out areas that don't match.

``` sql
CREATE INDEX index_welsh_constituencies_on_boundary ON welsh_constituencies USING GIST (boundary);
```

Next, import the region boundary line data use the `ogr2ogr` tool. 

``` sh
ogr2ogr -nlt PROMOTE_TO_MULTI -f "PostgreSQL" PG:"host=localhost dbname=<your-local-database>" scotland_and_wales_region.shp
```

Once this is done you should have the table `scotland_and_wales_region` in your database. Since the table contain both Scottish and Welsh boundaries we need to filter out the Welsh data. We can do this by creating a materialized view again.

``` sql
CREATE MATERIALIZED VIEW welsh_regions AS
SELECT code, REPLACE(name, ' PER', '') AS name, wkb_geometry AS boundary
FROM scotland_and_wales_region
WHERE area_code = 'WPE'
ORDER BY code;
```

The views also do some housekeeping on the names to remove the unnecessary suffixes for our purposes.

Next you’ll need to import the output area to constituency to region lookup. Start off by create a table to hold the import:

``` sql
CREATE TABLE welsh_oa_to_constituency_to_region_lookup (
  OA11CD character(9),
  NAWC18CD character(9),
  NAWC18NM character varying(100),
  NAWER18CD character(9),
  NAWER18NM character varying(100),
  FID integer PRIMARY KEY
);
```

Now import the data file using the `COPY` SQL command:

``` sql
COPY welsh_oa_to_constituency_to_region_lookup FROM '/path/to/oa_to_constituency_to_region_lookup.csv' WITH DELIMITER ',' CSV HEADER;
```

If you’re on a Mac you may get a warning about postgres wanting access to the filesystem depending on the path to the CSV file (e.g. if it's on your desktop).

We need to filter this down to just a constituency to region lookup which we’ll do with a materialized view again:

``` sql
CREATE MATERIALIZED VIEW welsh_constituency_to_region_lookup AS
SELECT nawc18cd, nawer18cd
FROM welsh_oa_to_constituency_to_region_lookup
GROUP BY nawc18cd, nawer18cd
ORDER BY nawc18cd;
```

Also create an index on the constituency code column to make the join more efficient later on:

``` sql
CREATE INDEX index_welsh_constituency_to_region_lookup_on_nawc18cd ON welsh_constituency_to_region_lookup(nawc18cd);
```

Next you’ll need to import the ONS Postcode Directory. This file is very large (in excess of 1GB) but we only need a subset of the data so create the following table to import into:

``` sql
CREATE TABLE postcodes (
  pcds character varying(8) PRIMARY KEY,
  dointr character(6),
  doterm character(6),
  oseast1m character varying(8),
  osnrth1m character varying(8),
  ctry character(9)
);
```

This is the meaning of each of the columns:

| Column   | Description                             |
|----------|-----------------------------------------|
| pcds     | Unit postcode - variable length version |
| ctry     | Country                                 |
| oseast1m | National grid reference - Easting       |
| osnrth1m | National grid reference - Northing      |
| dointr   | Date of introduction                    |
| doterm   | Date of termination                     |

To do the import you can use the `COPY` SQL command to read the data but you’ll need to process the CSV file through `cut` first:

``` sh
cut -d, -f3,4,5,12,13,17 ONSPD_NOV_2020_UK.csv > ONSPD_REDUCED.csv
```

This reduces the data down to a more manageable ~150MB.

Now import the CSV into the postcodes table:

``` sql
COPY postcodes FROM '/path/to/ONSPD_REDUCED.csv' WITH DELIMITER ',' CSV HEADER;
```

We now need to created materialized views for just the Welsh postcodes:

``` sql
CREATE MATERIALIZED VIEW welsh_postcodes AS
SELECT REPLACE(pcds, ' ', '') AS postcode, 
ST_SetSRID(ST_MakePoint(oseast1m::integer, osnrth1m::integer), 27700) AS location 
FROM postcodes WHERE ctry = 'W92000004' AND oseast1m != '' AND osnrth1m != '';
```

This view removes the space from the postcode and filters out any postcodes that don't have a corresponding location - the latter are typically PO boxes. We also set the coordinate system of the location to the OS National Grid.

For performance reasons we again create an index on the location column:

``` sql
CREATE INDEX index_welsh_postcodes_on_location ON welsh_postcodes USING GIST (location);
```

You should now have all the data you need to create the lookup tables.

## Creating the lookups

This stage is the core of the processing - for each postcode we need to run a `st_within` function against each constituency/region boundary to check which one it is in. Again for performance reasons we’ll use materialized views:

``` sql
CREATE MATERIALIZED VIEW welsh_postcode_lookup AS
SELECT p.postcode, r.spr20cd AS region_id, c.code AS constituency_id
FROM welsh_postcodes p
JOIN welsh_constituencies c ON st_within(p.location, c.boundary)
JOIN welsh_constituency_to_region_lookup AS r ON c.code = r.spc20cd;
```

This is the final table we need to generate our final geography CSV files - export using the following `COPY` commands:

``` sql
# regions.csv
COPY (
  SELECT r.code AS id, r.name AS name_en, '' AS name_cy
  FROM welsh_regions AS r ORDER BY r.code
) TO '/path/to/regions.csv' WITH CSV HEADER FORCE QUOTE *;
```

``` sql
# constituencies.csv
COPY (
  SELECT c.code AS id, (
    SELECT r.region_id
    FROM welsh_postcode_lookup AS r
    WHERE r.constituency_id = c.code LIMIT 1
  ) AS region_id,
  c.name AS name_en, '' AS name_cy, (
    SELECT p.postcode 
    FROM welsh_postcode_lookup AS p 
    WHERE p.constituency_id = c.code
    ORDER BY random() LIMIT 1
  ) AS example_postcode
  FROM welsh_constituencies AS c
  ORDER BY code
) TO '/path/to/constituencies.csv' WITH CSV HEADER FORCE QUOTE *;
```

``` sql
# postcodes.csv
COPY (
  SELECT postcode AS id, constituency_id
  FROM welsh_postcode_lookup ORDER BY postcode
) TO '/path/to/postcodes.csv' WITH CSV HEADER FORCE QUOTE *;
```

Send the `regions.csv` and `constituencies.csv` to the translations team to fill out the `name_gd` column. Once received replace the existing files and commit to the repo.

[1]: https://osdatahub.os.uk/downloads/open/BoundaryLine
[2]: https://geoportal.statistics.gov.uk/datasets/ons-postcode-directory-november-2021
[3]: https://geoportal.statistics.gov.uk/datasets/ons::output-area-to-national-assembly-for-wales-constituency-to-national-assembly-for-wales-electoral-region-december-2018-lookup-in-wales/explore
[4]: https://www.postgresql.org/docs/10/sql-creatematerializedview.html
