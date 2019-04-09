module GeoipLookup
  extend ActiveSupport::Concern

  module ClassMethods
    def geoip_lookup(ip)
      geoip_db.lookup(ip)
    rescue Errno::ENOENT => e
      nil
    end

    def iso_code_for(ip)
      if result = geoip_lookup(ip)
        result.found? ? result.country.iso_code : nil
      end
    end

    def country_name_for(ip)
      if result = geoip_lookup(ip)
        result.found? ? result.country.name : nil
      end
    end

    private

    def geoip_db
      Thread.current[:__geoip_db__] ||= MaxMindDB.new(ENV.fetch('GEOIP_DB_PATH'))
    end
  end

  def geoip_lookup(ip)
    self.class.geoip_lookup(ip)
  end

  def iso_code_for(ip)
    self.class.iso_code_for(ip)
  end

  def country_name_for(ip)
    self.class.country_name_for(ip)
  end

  def ip_location
    return unless ip_address?

    if iso_code = iso_code_for(ip_address)
      "#{ip_address} (#{iso_code})"
    else
      ip_address
    end
  end
end
