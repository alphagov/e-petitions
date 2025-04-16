class Page < ActiveRecord::Base
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[-a-z0-9]+\z/ }
  validates :slug, length: { maximum: 100 }
  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true
  validates :redirect_url, presence: true, if: :redirect?

  with_options allow_blank: true do
    validates :redirect_url, format: { with: /\Ahttps:\/\/www\.parliament\.uk\/.*\z/ }
  end

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
