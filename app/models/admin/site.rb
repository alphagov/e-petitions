require 'list_processor'

class Admin::Site < ActiveRecord::Base
  include ListProcessor

  validate :no_petitions_have_deleted_tags, on: :update, if: :petition_tags_changed?

  def petition_tags=(value)
    @allowed_petition_tags = nil
    super(normalize_lines(value))
  end

  def allowed_petition_tags
    @allowed_petition_tags || petition_tags_map
  end

  private

  def petition_tags_map(tags=petition_tags)
    strip_blank_lines(strip_comments(tags)).map(&:strip)
  end

  def no_petitions_have_deleted_tags
    deleted_tags = petition_tags_map(petition_tags_was) - petition_tags_map

    petitions_with_deleted_tags = deleted_tags.each do |tag, petitions|
      petitions = Petition.where("'#{tag}' = ANY (tags)")
      if petitions.any?
        error_message = "Tag '#{tag}' still being used on petitions: #{petitions.pluck(:id).join(', ')}"
        errors.add(:petition_tags, error_message)
      end
    end
  end
end
