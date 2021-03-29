json.cache! [I18n.locale, @petition], expires_in: 5.minutes do
  json.links do
    json.self request.url
  end

  json.data do
    json.partial! 'petition', petition: @petition
  end
end
