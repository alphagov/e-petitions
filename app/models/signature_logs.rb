require 'aws-sdk'
require 'ipaddr'

class SignatureLogs
  class Log
    PATTERN = /(?<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - .{0}- \[(?<day>[\d]{2})\/(?<month>[\w]+)\/(?<year>[\d]{4})\:(?<hour>[\d]{2})\:(?<min>[\d]{2})\:(?<sec>[\d]{2}) [^$]+\] "(?<method>GET|POST|PUT|DELETE) (?<uri>[^\s]+?) HTTP\/1\.1" (?<response>[\d]+) [\d]+ "(?<referrer>[^\s]+?)" "(?<agent>[^\"]+?)"/
    MONTHS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    attr_reader :message, :data

    def initialize(message)
      @message = message
      @data = message.match(PATTERN)
    end

    def ip_address
      @ip_address ||= ::IPAddr.new(data["ip"])
    end

    def timestamp
      @timestamp ||= ::Time.utc(year, month, day, hour, min, sec).in_time_zone
    end

    def method
      data["method"]
    end

    def uri
      data["uri"]
    end

    def response
      data["response"]
    end

    def referrer
      data["referrer"]
    end

    def agent
      data["agent"]
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

  delegate :size, :empty?, to: :events

  class << self
    def find(id)
      new(id)
    end
  end

  def initialize(id)
    @signature = Signature.find(id)
  end

  def each(&block)
    events.each { |event| yield Log.new(event.message) }
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

  def events
    @events ||= fetch_events
  end

  def fetch_events
    fetch_create_events + fetch_validate_events
  end

  def fetch_create_events
    request = {
      log_group_name: log_group_name,
      start_time: ms(created_at - 5.minutes),
      end_time: ms(created_at + 5.minutes),
      filter_pattern: ip_address,
      interleaved: false
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
      interleaved: false
    }

    client.filter_log_events(request).events
  rescue Aws::CloudWatchLogs::Errors::ServiceError => e
    []
  end
end
