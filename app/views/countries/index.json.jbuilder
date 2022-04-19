json.cache! [I18n.locale, :countries], expires_in: 1.hour do
  json.array! @countries do |country|
    json.id country.id
    json.name country.name
    json.population country.population
  end
end
