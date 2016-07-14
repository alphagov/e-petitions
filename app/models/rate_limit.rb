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
      domains
    rescue StandardError => e
      errors.add :domain_whitelist, :invalid
    end

    begin
      ips
    rescue StandardError => e
      errors.add :ip_whitelist, :invalid
    end
  end

  def exceeded?(signature)
    return false if domain_whitelisted?(signature.domain)
    return false if ip_whitelisted?(signature.ip_address)

    burst_rate_exceeded?(signature) || sustained_rate_exceeded?(signature)
  end

  def domain_whitelist=(value)
    @domains = nil
    super(normalize_lines(value))
  end

  def domains
    @domains ||= build_domain_whitelist
  end

  def ip_whitelist=(value)
    @ips = nil
    super(normalize_lines(value))
  end

  def ips
    @ips ||= build_ip_whitelist
  end

  private

  def strip_comments(whitelist)
    whitelist.gsub(/#.*$/, '')
  end

  def strip_blank_lines(whitelist)
    whitelist.each_line.reject(&:blank?)
  end

  def build_domain_whitelist
    whitelist = strip_comments(domain_whitelist)
    whitelist = strip_blank_lines(whitelist)

    whitelist.map{ |l| %r[\A#{convert_glob(l.strip)}\z] }
  end

  def domain_whitelisted?(domain)
    domains.any?{ |d| d === domain }
  end

  def build_ip_whitelist
    whitelist = strip_comments(ip_whitelist)
    whitelist = strip_blank_lines(whitelist)

    whitelist.map{ |l| IPAddr.new(l.strip) }
  end

  def ip_whitelisted?(ip)
    ips.any?{ |i| i.include?(ip) }
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
