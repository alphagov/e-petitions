json.cache! [I18n.locale, :constituencies], expires_in: 1.hour do
  json.array! @constituencies do |constituency|
    json.id constituency.id
    json.name constituency.name

    if constituency.member
      json.partial! 'member', member: constituency.member
    else
      json.member nil
    end

    json.partial! 'region', region: constituency.region
  end
end
