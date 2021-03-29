require 'ipaddr'

class RateLimit < ActiveRecord::Base
  GLOB_PATTERN = /^(\*\*\.|\*\.)/
  RECURSIVE_GLOB = "**."
  RECURSIVE_PATTERN = "(?:[-a-z0-9]+\\.)+"
  SINGLE_GLOB = "*."
  SINGLE_PATTERN = "(?:[-a-z0-9]+\\.)"
  DOMAIN_PATTERN = /^(?:[a-z0-9][a-z0-9-]{0,61}[a-z0-9]\.)+[a-z]{2,}$/

  validates :burst_rate, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :burst_period, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :sustained_rate, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :sustained_period, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :creator_rate, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :sponsor_rate, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :feedback_rate, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :allowed_domains, length: { maximum: 10000, allow_blank: true }
  validates :allowed_ips, length: { maximum: 10000, allow_blank: true }
  validates :blocked_domains, length: { maximum: 50000, allow_blank: true }
  validates :blocked_ips, length: { maximum: 50000, allow_blank: true }
  validates :countries, length: { maximum: 2000, allow_blank: true }
  validates :country_burst_rate, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :country_sustained_rate, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :threshold_for_logging_trending_items, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :threshold_for_notifying_trending_items, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :trending_items_notification_url, length: { maximum: 100, allow_blank: true }
  validates :ignored_domains, length: { maximum: 10000, allow_blank: true }

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

    unless country_sustained_rate.nil? || country_burst_rate.nil?
      if country_sustained_rate <= country_burst_rate
        errors.add :country_sustained_rate, "Country sustained rate must be greater than country burst rate"
      end
    end

    begin
      allowed_domains_list
    rescue StandardError => e
      errors.add :allowed_domains, :invalid
    end

    begin
      allowed_ips_list
    rescue StandardError => e
      errors.add :allowed_ips, :invalid
    end

    begin
      blocked_domains_list
    rescue StandardError => e
      errors.add :blocked_domains, :invalid
    end

    begin
      blocked_ips_list
    rescue StandardError => e
      errors.add :blocked_ips, :invalid
    end

    begin
      ignored_domains_list
    rescue StandardError => e
      errors.add :ignored_domains, :invalid
    end
  end

  def reload
    @allowed_domains_list = nil
    @blocked_domains_list = nil
    @allowed_ips_list = nil
    @blocked_ips_list = nil
    @allowed_countries = nil
    @ignored_domains_list = nil

    super
  end

  def exceeded?(signature)
    return true if ip_blocked?(signature.ip_address)
    return true if ip_geoblocked?(signature.ip_address)
    return true if domain_blocked?(signature.domain)
    return false if ip_allowed?(signature.ip_address)
    return false if domain_allowed?(signature.domain)

    if signature.is_a?(Feedback)
      feedback_rate_exceeded?(signature)
    elsif signature.creator?
      creator_rate_exceeded?(signature)
    elsif signature.sponsor?
      sponsor_rate_exceeded?(signature)
    elsif use_country_rate?(signature.ip_address)
      country_rate_exceeded?(signature)
    else
      rate_exceeded?(signature)
    end
  end

  def ignore_domain?(domain)
    domain_blocked?(domain) || domain_allowed?(domain)
  end

  def ignore_ip?(ip)
    ip_blocked?(ip) || ip_allowed?(ip) || ip_geoblocked?(ip)
  end

  def allowed_domains=(value)
    @allowed_domains_list = nil
    super(normalize_lines(value))
  end

  def allowed_domains_list
    @allowed_domains_list ||= build_allowed_domains
  end

  def blocked_domains=(value)
    @blocked_domains_list = nil
    super(normalize_lines(value))
  end

  def blocked_domains_list
    @blocked_domains_list ||= build_blocked_domains
  end

  def allowed_ips=(value)
    @allowed_ips_list = nil
    super(normalize_lines(value))
  end

  def allowed_ips_list
    @allowed_ips_list ||= build_allowed_ips
  end

  def blocked_ips=(value)
    @blocked_ips_list = nil
    super(normalize_lines(value))
  end

  def blocked_ips_list
    @blocked_ips_list ||= build_blocked_ips
  end

  def allowed_countries
    @allowed_countries ||= build_allowed_countries
  end

  def countries=(value)
    @allowed_countries = nil
    super(normalize_lines(value))
  end

  def ignored_domains=(value)
    @ignored_domains_list = nil
    super(normalize_lines(value))
  end

  def ignored_domains_list
    @ignored_domains_list ||= build_ignored_domains
  end

  private

  def strip_comments(list)
    list.gsub(/#.*$/, '')
  end

  def strip_blank_lines(list)
    list.each_line.reject(&:blank?)
  end

  def build_allowed_domains
    domains = strip_comments(allowed_domains)
    domains = strip_blank_lines(domains)

    domains.map{ |l| %r[\A#{convert_glob(l.strip)}\z] }
  end

  def domain_allowed?(domain)
    allowed_domains_list.any?{ |d| d === domain }
  end

  def build_blocked_domains
    domains = strip_comments(blocked_domains)
    domains = strip_blank_lines(domains)

    domains.map{ |l| %r[\A#{convert_glob(l.strip)}\z] }
  end

  def domain_blocked?(domain)
    blocked_domains_list.any?{ |d| d === domain }
  end

  def build_allowed_ips
    ips = strip_comments(allowed_ips)
    ips = strip_blank_lines(ips)

    ips.map{ |l| IPAddr.new(l.strip) }
  end

  def ip_allowed?(ip)
    allowed_ips_list.any?{ |i| i.include?(ip) }
  end

  def build_blocked_ips
    ips = strip_comments(blocked_ips)
    ips = strip_blank_lines(ips)

    ips.map{ |l| IPAddr.new(l.strip) }
  end

  def ip_blocked?(ip)
    blocked_ips_list.any?{ |i| i.include?(ip) }
  end

  def build_ignored_domains
    strip_blank_lines(strip_comments(ignored_domains)).map { |d| validate_domain!(d.strip) }
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

  def validate_domain!(domain)
    if domain =~ DOMAIN_PATTERN
      domain
    else
      raise ArgumentError, "Invalid domain: #{domain.inspect}"
    end
  end

  def normalize_lines(value)
    value.to_s.strip.gsub(/\r\n|\r/, "\n")
  end

  def use_country_rate?(ip)
    if country_rate_limits_enabled?
      allowed_countries.include?(country_for_ip(ip))
    else
      false
    end
  end

  def country_rate_exceeded?(signature)
    country_burst_rate_exceeded?(signature) || country_sustained_rate_exceeded?(signature)
  end

  def country_burst_rate_exceeded?(signature)
    country_burst_rate < signature.rate(burst_period)
  end

  def country_sustained_rate_exceeded?(signature)
    country_sustained_rate < signature.rate(sustained_period)
  end

  def rate_exceeded?(signature)
    burst_rate_exceeded?(signature) || sustained_rate_exceeded?(signature)
  end

  def burst_rate_exceeded?(signature)
    burst_rate < signature.rate(burst_period)
  end

  def sustained_rate_exceeded?(signature)
    sustained_rate < signature.rate(sustained_period)
  end

  def creator_rate_exceeded?(signature)
    creator_rate < signature.rate(sustained_period)
  end

  def sponsor_rate_exceeded?(signature)
    sponsor_rate < signature.rate(sustained_period)
  end

  def feedback_rate_exceeded?(feedback)
    feedback_rate < feedback.rate(sustained_period)
  end
end
