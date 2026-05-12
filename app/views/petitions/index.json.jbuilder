json.links do
  json.self request.url

  json.first petitions_url(:json, @petitions.first_params)
  json.last petitions_url(:json, @petitions.last_params)

  if @petitions.last_page?
    json.next nil
  else
    json.next petitions_url(:json, @petitions.next_params)
  end

  if @petitions.first_page?
    json.prev nil
  else
    json.prev petitions_url(:json, @petitions.previous_params)
  end
end

json.data @petitions do |petition|
  json.partial! 'petition', petition: petition, is_collection: true
end
