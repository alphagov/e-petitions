require 'postcode_sanitizer'

module ConstituencyApi
  class Error < RuntimeError; end

  class Constituency
    attr_reader :id, :name, :mp

    def initialize(id, name, mp = nil)
      @id, @name, @mp = id, name, mp
    end

    def ==(other)
      other.is_a?(self.class) && id == other.id && name == other.name && mp == other.mp
    end
    alias_method :eql?, :==
  end

  class Mp
    attr_reader :id, :name, :start_date
    URL = "http://www.parliament.uk/biographies/commons"

    def initialize(id, name, start_date)
      @id, @name, @start_date = id, name, start_date.to_date
    end

    def url
      "#{URL}/#{name.parameterize}/#{id}"
    end

    def ==(other)
      other.is_a?(self.class) && id == other.id && name == other.name && start_date && other.start_date
    end
    alias_method :eql?, :==
  end

  class Client
    include Faraday
    URL = 'http://data.parliament.uk/membersdataplatform/services/mnis/Constituencies'
    TIMEOUT = 5

    def self.constituency(postcode)
      constituencies(postcode).first
    end

    def self.constituencies(postcode)
      response = call_api(postcode)
      parse_constituencies(response)
    end

    def self.parse_constituencies(response)
      return [] unless response["Constituencies"]
      constituencies = response["Constituencies"]["Constituency"]
      Array.wrap(constituencies).map { |c| Constituency.new(c["Constituency_Id"], c["Name"], last_mp(c)) }
    end

    def self.call_api(postcode)
      sanitized_postcode = PostcodeSanitizer.call(postcode)
      response = Faraday.new(URL).get("#{sanitized_postcode}/") do |req|
        req.options[:timeout] = TIMEOUT
        req.options[:open_timeout] = TIMEOUT
      end
      unless response.status == 200
        raise Error.new("Unexpected response from API:"\
                        "status #{response.status}"\
                        "body #{response.body}"\
                        "request #{URL}/#{sanitized_postcode}/")
      end
      Hash.from_xml(response.body)
    rescue Faraday::Error::TimeoutError
      raise Error.new("Timeout after #{TIMEOUT} seconds")
    rescue Faraday::Error => e
      raise Error.new("Network error - #{e}")
    end

    def self.last_mp(constituency_hash)
      mps = parse_mps(constituency_hash)
      mps.select(&:start_date).sort_by(&:start_date).last
    end

    def self.parse_mps(response)
      return [] unless response["RepresentingMembers"]
      mps = response["RepresentingMembers"]["RepresentingMember"]
      Array.wrap(mps).map { |m| Mp.new(m["Member_Id"], m["Member"], m["StartDate"]) }
    end

    private_class_method :parse_constituencies, :call_api, :parse_mps, :last_mp
  end
end

