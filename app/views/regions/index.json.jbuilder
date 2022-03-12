json.cache! [I18n.locale, :regions], expires_in: 1.hour do
  json.array! @regions do |region|
    json.id region.id
    json.name region.name

    json.members region.members do |member|
      json.partial! 'member', member: member
    end
  end
end
