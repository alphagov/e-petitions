require 'list_processor'

class Admin::Site < ActiveRecord::Base
  include ListProcessor

  validate :duplicate_tags_not_allowed
  validate :no_petitions_have_deleted_tags, on: :update, if: :petition_tags_changed?

  def petition_tags=(value)
    @allowed_petition_tags = nil
    super(normalize_lines(value))
  end

  def allowed_petition_tags(for_comparison: false)
    @allowed_petition_tags || petition_tags_map(petition_tags, for_comparison: for_comparison)
  end

  private

  def petition_tags_map(tags=petition_tags, for_comparison: false)
    tags_map = strip_blank_lines(strip_comments(tags)).map(&:strip)
    for_comparison ? tags_map.map(&:downcase) : tags_map
  end

  def duplicate_tags_not_allowed
    tag_counts = petition_tags_map(for_comparison: true).each_with_object(Hash.new(0)) do |tag, counts|
      counts[tag] += 1
    end

    duplicate_tags = tag_counts.collect { |tag, count| tag if count > 1 }.compact
    if duplicate_tags.any?
      error_message = "Duplicate tags not allowed: #{duplicate_tags.join(', ')}"
      errors.add(:petition_tags, error_message)
    end
  end

  def no_petitions_have_deleted_tags
    existing_tags = petition_tags_map(petition_tags_was, for_comparison: true)
    new_tags = petition_tags_map(for_comparison: true)
    deleted_tags = existing_tags - new_tags

    petitions_with_deleted_tags = deleted_tags.each do |tag|
      petitions = Petition.with_tag(tag)
      if petitions.any?
        error_message = "Tag '#{tag}' still being used on petitions: #{petitions.pluck(:id).join(', ')}"
        errors.add(:petition_tags, error_message)
      end
    end
  end
end
