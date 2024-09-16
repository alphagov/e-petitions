@topics.each do |topic|
  json.set! topic.code do
    json.code topic.code
    json.name topic.name
  end
end
