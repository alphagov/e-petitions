module TopicsHelper
  def topic_codes(ids)
    @topic_map ||= Topic.map

    ids.inject([]) do |codes, id|
      if topic = @topic_map[id]
        codes << { code: topic.code, name: topic.name }
      end

      codes
    end.sort_by { |t| t[:name] }
  end

  def topic_list(ids)
    @topic_map ||= Topic.map

    ids.inject([]) do |codes, id|
      if topic = @topic_map[id]
        codes << topic.code
      end

      codes
    end.sort.join(",")
  end
end
