require 'aws-sdk'
require 'ipaddr'

class SignatureLogs
  class Log
    PATTERN = /(?<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(?:, (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))* - .{0}- \[(?<day>[\d]{2})\/(?<month>[\w]+)\/(?<year>[\d]{4})\:(?<hour>[\d]{2})\:(?<min>[\d]{2})\:(?<sec>[\d]{2}) [^$]+\] "(?<method>GET|POST|PUT|DELETE) (?<uri>[^\s]+?) HTTP\/1\.1" (?<response>[\d]+) [\d]+ "(?<referrer>[^\s]+?)" "(?<agent>[^\"]+?)"/
    MONTHS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    attr_reader :message, :data

    def initialize(message)
      @message = message
      @data = message.match(PATTERN)
    end

    def blank?
      data.nil?
    end

    def ip_address
      if present?
        @ip_address ||= data && ::IPAddr.new(data["ip"])
      end
    end

    def timestamp
      if present?
        @timestamp ||= data && ::Time.utc(year, month, day, hour, min, sec).in_time_zone
      end
    end

    def method
      data["method"] if present?
    end

    def uri
      data["uri"] if present?
    end

    def response
      data["response"] if present?
    end

    def referrer
      data["referrer"] if present?
    end

    def agent
      data["agent"] if present?
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      message == other.message
    end

    private

    def year; data["year"].to_i; end
    def month; MONTHS.index(data["month"]) + 1; end
    def day; data["day"].to_i; end
    def hour; data["hour"].to_i; end
    def min; data["min"].to_i; end
    def sec; data["sec"].to_i; end
  end

  include Enumerable

  attr_reader :signature

  delegate :created_at, to: :signature
  delegate :ip_address, to: :signature
  delegate :validated_at, to: :signature
  delegate :validated_ip, to: :signature
  delegate :size, :empty?, to: :logs

  class << self
    def find(id)
      new(id)
    end
  end

  def initialize(id)
    @signature = Signature.find(id)
  end

  def each(&block)
    logs.each { |log| yield log }
  end

  private

  def client
    @client ||= Aws::CloudWatchLogs::Client.new
  end

  def log_group_name
    ENV.fetch("NGINX_LOG_GROUP_NAME", "nginx-access-logs")
  end

  def ms(time)
    (time.to_f * 1000).to_i
  end

  def logs
    @logs ||= fetch_events.map { |e| Log.new(e.message) }.reject(&:blank?).sort_by(&:timestamp)
  end

  def fetch_events
    if overlapping?
      fetch_combined_events
    else
      fetch_create_events + fetch_validate_events
    end
  end

  def overlapping?
    return false unless validated_at
    return false unless validated_ip
    return false unless ip_address == validated_ip

    (created_at + 5.minutes) >= (validated_at - 5.minutes)
  end

  def fetch_create_events
    request = {
      log_group_name: log_group_name,
      start_time: ms(created_at - 5.minutes),
      end_time: ms(created_at + 5.minutes),
      filter_pattern: ip_address,
      interleaved: true
    }

    client.filter_log_events(request).events

  rescue Aws::CloudWatchLogs::Errors::ServiceError => e
    []
  end

  def fetch_validate_events
    return [] unless validated_at
    return [] unless validated_ip

    request = {
      log_group_name: log_group_name,
      start_time: ms(validated_at - 5.minutes),
      end_time: ms(validated_at + 5.minutes),
      filter_pattern: validated_ip,
      interleaved: true
    }

    client.filter_log_events(request).events

  rescue Aws::CloudWatchLogs::Errors::ServiceError => e
    []
  end

  def fetch_combined_events
    request = {
      log_group_name: log_group_name,
      start_time: ms(created_at - 5.minutes),
      end_time: ms(validated_at + 5.minutes),
      filter_pattern: ip_address,
      interleaved: true
    }

    client.filter_log_events(request).events

  rescue Aws::CloudWatchLogs::Errors::ServiceError => e
    []
  end
end
