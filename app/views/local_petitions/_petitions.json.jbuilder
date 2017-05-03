json.constituency constituency.name

if constituency.sitting_mp?
  json.mp do
    json.name constituency.mp_name
    json.url constituency.mp_url
  end
end

json.petitions petitions do |petition|
  json.action petition.action
  json.url petition_url(petition)
  json.state petition.state
  json.constituency_signature_count petition.constituency_signature_count
  json.total_signature_count petition.signature_count
end
