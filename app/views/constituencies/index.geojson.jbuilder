json.cache! [I18n.locale, :constituencies, :geojson], expires_in: 1.hour do
  json.partial! "constituencies"
end
