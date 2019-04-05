class Feedback < ActiveRecord::Base
  validates :comment, presence: true, length: { maximum: 32768 }
  validates :petition_link_or_title, length: { maximum: 255 }, allow_blank: true
  validates :email, email: true, length: { maximum: 255 }, allow_blank: true

  def petition_link?
    petition_link_or_title =~ /\A#{Regexp.escape(Site.url)}/
  end
end
