json.cache! [I18n.locale, :topics], expires_in: 5.minutes do
  @topics.each do |topic|
    json.set! topic.code do
      json.code topic.code
      json.name topic.name
    end
  end
end
