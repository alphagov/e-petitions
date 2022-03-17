json.cache! [I18n.locale, :constituencies, :geojson], expires_in: 1.hour do
  json.type "FeatureCollection"

  json.features @constituencies do |constituency|
    json.type "Feature"

    json.properties do
      json.id constituency.id
      json.name constituency.name
      json.population constituency.population

      if member = constituency.member
        json.member do
          json.name member.name
          json.party member.party
          json.url member.url
        end
      else
        json.member nil
      end

      if region = constituency.region
        json.region do
          json.id region.id
          json.name region.name
          json.population region.population

          json.members region.members do |member|
            json.name member.name
            json.party member.party
            json.url member.url
          end
        end
      else
        json.region nil
      end
    end

    json.geometry RGeo::GeoJSON.encode(constituency.boundary)
  end
end
