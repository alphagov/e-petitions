class TrendingDomain < ActiveRecord::Base
  belongs_to :petition

  validates :domain, presence: true, length: { maximum: 100 }
  validates :count, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :starts_at, presence: true

  attr_readonly(:domain, :count, :starts_at)

  class << self
    def default_scope
      order(created_at: :desc, count: :desc)
    end

    def log!(time, domain, count)
      create!(domain: domain, count: count, starts_at: time)
    end

    def search(query, options = {})
      query = query.to_s
      page = [options[:page].to_i, 1].max

      if query.present?
        scope = where(domain: query)
      else
        scope = all
      end

      scope.paginate(page: page, per_page: 50)
    end
  end

  def ends_at
    starts_at.advance(hours: 1)
  end

  def window
    starts_at.getutc.iso8601(0)
  end
end
