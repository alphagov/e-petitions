class Page < ActiveRecord::Base
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[-a-z0-9]+\z/ }
  validates :slug, length: { maximum: 100 }
  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true

  DISSOLUTION_PAGES = %w[help]

  class << self
    def by_slug
      order(:slug)
    end
  end

  def to_param
    slug
  end

  def show_dissolution_warning?
    DISSOLUTION_PAGES.include?(slug)
  end
end
