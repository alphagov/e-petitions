json.cache! [I18n.locale, :countries, :geojson], expires_in: 1.hour do
  json.partial! "countries"
end
