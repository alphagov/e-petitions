json.region do
  json.id region.id
  json.name region.name

  json.members region.members do |member|
    json.partial! 'member', member: member
  end
end
