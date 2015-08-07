json.links do
  json.self request.url
  json.merge! ApiPaginationLinksPresenter.new(@petitions).serialize
end

json.data @petitions do |petition|
  json.partial! 'petition', petition: petition, is_collection: true
end
