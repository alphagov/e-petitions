json.cache! [I18n.locale, :all_local_petitions, @constituency], expires_in: 5.minutes do
  json.partial! 'petitions', petitions: @petitions, constituency: @constituency
end
