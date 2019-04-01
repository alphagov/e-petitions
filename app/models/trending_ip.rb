class TrendingIp < ActiveRecord::Base
  belongs_to :petition

  validates :ip_address, presence: true
  validates :country_code, presence: true, format: { with: /\A[A-Z]{2}\z/ }
  validates :count, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :starts_at, presence: true

  attr_readonly(:ip_address, :country_code, :count, :starts_at)

  before_validation on: :create do
    result = geoip_db.lookup(ip_address.to_s)

    if result.found?
      self.country_code ||= result.country.iso_code
    else
      self.country_code ||= "XX"
    end
  end

  class << self
    def default_scope
      order(created_at: :desc, count: :desc)
    end

    def log!(time, ip_address, count)
      create!(ip_address: ip_address, count: count, starts_at: time)
    end

    def search(query, options = {})
      query = query.to_s
      page = [options[:page].to_i, 1].max

      if query.present?
        scope = where("ip_address <<= ?", query)
      else
        scope = all
      end

      scope.paginate(page: page, per_page: 50)
    end
  end

  def ends_at
    starts_at.advance(hours: 1)
  end

  private

  def geoip_db
    @geoip_db ||= MaxMindDB.new(ENV.fetch('GEOIP_DB_PATH'))
  end
end
