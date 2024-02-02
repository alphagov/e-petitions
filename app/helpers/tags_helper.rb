module TagsHelper
  def tag_names(tags)
    tags.each_with_object([]) do |tag, names|
      if name = tag_mapping[tag]
        names << name
      end
    end.sort.join(", ")
  end

  private

  def tag_mapping
    @tag_name_map ||= Tag.pluck(:id, :name).to_h
  end
end
