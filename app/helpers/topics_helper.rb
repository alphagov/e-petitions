module TopicsHelper
  def topic_codes(ids)
    @topic_map ||= Topic.map

    ids.inject([]) do |codes, id|
      if topic = @topic_map[id]
        codes << topic.code
      end

      codes
    end.sort
  end
end
