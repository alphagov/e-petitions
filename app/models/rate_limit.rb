require 'ipaddr'

class RateLimit < ActiveRecord::Base
  GLOB_PATTERN = /^(\*\*\.|\*\.)/
  RECURSIVE_GLOB = "**."
  RECURSIVE_PATTERN = "(?:[-a-z0-9]+\\.)+"
  SINGLE_GLOB = "*."
  SINGLE_PATTERN = "(?:[-a-z0-9]+\\.)"

  validates :burst_rate, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :burst_period, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :sustained_rate, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :sustained_period, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :domain_whitelist, length: { maximum: 10000, allow_blank: true }
  validates :ip_whitelist, length: { maximum: 10000, allow_blank: true }
  validates :domain_blacklist, length: { maximum: 50000, allow_blank: true }
  validates :ip_blacklist, length: { maximum: 50000, allow_blank: true }
  validates :countries, length: { maximum: 2000, allow_blank: true }

  validate do
    unless sustained_rate.nil? || burst_rate.nil?
      if sustained_rate <= burst_rate
        errors.add :sustained_rate, "Sustained rate must be greater than burst rate"
      end
    end

    unless sustained_period.nil? || burst_period.nil?
      if sustained_period <= burst_period
        errors.add :sustained_period, "Sustained period must be greater than burst period"
      end
    end

    begin
      whitelisted_domains
    rescue StandardError => e
      errors.add :domain_whitelist, :invalid
    end

    begin
      whitelisted_ips
    rescue StandardError => e
      errors.add :ip_whitelist, :invalid
    end

    begin
      blacklisted_domains
    rescue StandardError => e
      errors.add :domain_blacklist, :invalid
    end

    begin
      blacklisted_ips
    rescue StandardError => e
      errors.add :ip_blacklist, :invalid
    end
  end

  def exceeded?(signature)
    return false if domain_whitelisted?(signature.domain)
    return false if ip_whitelisted?(signature.ip_address)
    return true if domain_blacklisted?(signature.domain)
    return true if ip_blacklisted?(signature.ip_address)
    return true if ip_geoblocked?(signature.ip_address)

    burst_rate_exceeded?(signature) || sustained_rate_exceeded?(signature)
  end

  def domain_whitelist=(value)
    @whitelisted_domains = nil
    super(normalize_lines(value))
  end

  def whitelisted_domains
    @whitelisted_domains ||= build_domain_whitelist
  end

  def domain_blacklist=(value)
    @blacklisted_domains = nil
    super(normalize_lines(value))
  end

  def blacklisted_domains
    @blacklisted_domains ||= build_domain_blacklist
  end

  def ip_whitelist=(value)
    @whitelisted_ips = nil
    super(normalize_lines(value))
  end

  def whitelisted_ips
    @whitelisted_ips ||= build_ip_whitelist
  end

  def ip_blacklist=(value)
    @blacklisted_ips = nil
    super(normalize_lines(value))
  end

  def blacklisted_ips
    @blacklisted_ips ||= build_ip_blacklist
  end

  def allowed_countries
    @allowed_countries ||= build_allowed_countries
  end

  def countries=(value)
    @allowed_countries = nil
    super(normalize_lines(value))
  end

  private

  def strip_comments(list)
    list.gsub(/#.*$/, '')
  end

  def strip_blank_lines(list)
    list.each_line.reject(&:blank?)
  end

  def build_domain_whitelist
    whitelist = strip_comments(domain_whitelist)
    whitelist = strip_blank_lines(whitelist)

    whitelist.map{ |l| %r[\A#{convert_glob(l.strip)}\z] }
  end

  def domain_whitelisted?(domain)
    whitelisted_domains.any?{ |d| d === domain }
  end

  def build_domain_blacklist
    blacklist = strip_comments(domain_blacklist)
    blacklist = strip_blank_lines(blacklist)

    blacklist.map{ |l| %r[\A#{convert_glob(l.strip)}\z] }
  end

  def domain_blacklisted?(domain)
    blacklisted_domains.any?{ |d| d === domain }
  end

  def build_ip_whitelist
    whitelist = strip_comments(ip_whitelist)
    whitelist = strip_blank_lines(whitelist)

    whitelist.map{ |l| IPAddr.new(l.strip) }
  end

  def ip_whitelisted?(ip)
    whitelisted_ips.any?{ |i| i.include?(ip) }
  end

  def build_ip_blacklist
    blacklist = strip_comments(ip_blacklist)
    blacklist = strip_blank_lines(blacklist)

    blacklist.map{ |l| IPAddr.new(l.strip) }
  end

  def ip_blacklisted?(ip)
    blacklisted_ips.any?{ |i| i.include?(ip) }
  end

  def build_allowed_countries
    strip_blank_lines(strip_comments(countries)).map(&:strip)
  end

  def ip_geoblocked?(ip)
    geoblocking_enabled? && country_blocked?(ip)
  end

  def country_blocked?(ip)
    allowed_countries.exclude?(country_for_ip(ip))
  end

  def country_for_ip(ip)
    result = geoip_db.lookup(ip)

    if result.found?
      result.country.name
    else
      "UNKNOWN"
    end
  end

  def geoip_db
    @geoip_db ||= MaxMindDB.new(ENV.fetch('GEOIP_DB_PATH'))
  end

  def convert_glob(pattern)
    pattern.gsub(GLOB_PATTERN) do |match|
      if match == RECURSIVE_GLOB
        RECURSIVE_PATTERN
      elsif match == SINGLE_GLOB
        SINGLE_PATTERN
      end
    end
  end

  def normalize_lines(value)
    value.to_s.strip.gsub(/\r\n|\r/, "\n")
  end

  def burst_rate_exceeded?(signature)
    burst_rate < signature.rate(burst_period)
  end

  def sustained_rate_exceeded?(signature)
    sustained_rate < signature.rate(sustained_period)
  end
end
