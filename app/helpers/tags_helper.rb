module TagsHelper
  SHOW_TAGS_COLUMN = %i[
    collecting_sponsors
    flagged
    dormant
    in_moderation
    recently_in_moderation
    nearly_overdue_in_moderation
    overdue_in_moderation
    tagged_in_moderation
    untagged_in_moderation
  ]

  def show_tags_column?(scope)
    scope.in?(SHOW_TAGS_COLUMN)
  end

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
