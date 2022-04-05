RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  epsg_4326 = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs"
  epsg_27700 = "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs +type=crs"

  options = {
    proj4: epsg_4326, srid: 4326,
    projection_proj4: epsg_27700, projection_srid: 27700
  }

  config.default = RGeo::Geographic.projected_factory(options)
end
