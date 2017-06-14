module AdminTagsValidation
  extend ActiveSupport::Concern

  included do
    validate :tags_must_be_allowed
  end

  def tags_for_comparison
    tags.map(&:downcase)
  end

  private

  def admin_site_settings
    @admin_site_settings ||= Admin::Site.first_or_create!
  end

  def tags_must_be_allowed
    return if tags.nil?
    disallowed_tags = (tags_for_comparison || []) - admin_site_settings.allowed_petition_tags
    disallowed_tags_with_quotes = disallowed_tags.map { |tag| "'#{tag}'" }
    errors.add(:tags, "Disallowed tags: #{disallowed_tags_with_quotes.join(', ')}") unless disallowed_tags.empty?
  end
end