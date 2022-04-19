json.type "FeatureCollection"

json.features @countries do |country|
  json.type "Feature"

  json.properties do
    json.id country.id
    json.name country.name
    json.population country.population
  end

  json.geometry RGeo::GeoJSON.encode(country.boundary)
end
