require 'list_processor'

class Admin::Site < ActiveRecord::Base
  include ListProcessor

  def petition_tags=(value)
    @allowed_petition_tags = nil
    super(normalize_lines(value))
  end

  def allowed_petition_tags
    @allowed_petition_tags || build_allowed_petition_tags
  end

  private

  def build_allowed_petition_tags
    strip_blank_lines(strip_comments(petition_tags)).map(&:strip)
  end
end
