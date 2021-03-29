json.cache! [I18n.locale, :local_petitions, @constituency], expires_in: 5.minutes do
  json.partial! 'petitions'
end
