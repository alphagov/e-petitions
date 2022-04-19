json.cache! [I18n.locale, :regions, :geojson], expires_in: 1.hour do
  json.partial! "regions"
end
