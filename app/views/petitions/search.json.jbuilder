json.links do
  json.self request.url

  json.first search_petitions_url(:json, @petitions.first_page)
  json.last search_petitions_url(:json, @petitions.last_page)

  if @petitions.last_page?
    json.next nil
  else
    json.next search_petitions_url(:json, @petitions.next_page)
  end

  if @petitions.first_page?
    json.prev nil
  else
    json.prev search_petitions_url(:json, @petitions.previous_page)
  end
end

json.data @petitions do |petition|
  json.partial! 'petition', petition: petition, is_collection: true
end
