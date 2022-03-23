json.type "FeatureCollection"

json.features @regions do |region|
  json.type "Feature"

  json.properties do
    json.id region.id
    json.name region.name
    json.population region.population

    json.members region.members do |member|
      json.name member.name
      json.party member.party
      json.url member.url
      json.colour member.colour
    end
  end

  json.geometry RGeo::GeoJSON.encode(region.boundary)
end
