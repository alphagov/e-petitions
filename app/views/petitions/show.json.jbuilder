json.links do
  json.self request.url
end

json.data do
  json.partial! 'petition', petition: @petition
end
