module ConstituencyApi
  ConstituencyApiError = Class.new(RuntimeError)

  class Constituency < Struct.new(:name, :mp)
  end

  class Mp < Struct.new(:id, :name, :start_date)
    URL = "http://www.parliament.uk/biographies/commons"
    def url
      "#{URL}/#{name.parameterize}/#{id}"
    end
  end

  class Client
    include Faraday
    URL = 'http://data.parliament.uk/membersdataplatform/services/mnis/Constituencies'
    TIMEOUT = 5

    def self.constituencies(postcode)
      response = call_api(postcode)
      parse_constituencies(response)
    end

    def self.parse_constituencies(response)
      return [] unless response["Constituencies"]
      constituencies = response["Constituencies"]["Constituency"]
      Array.wrap(constituencies).map { |c| Constituency.new(c["Name"], last_mp(c)) }
    end

    def self.call_api(postcode)
      response = Faraday.new(URL).get("#{postcode_param(postcode)}/") do |req|
        req.options[:timeout] = TIMEOUT
        req.options[:open_timeout] = TIMEOUT
      end
      unless response.status == 200
        raise ConstituencyApiError.new("Unexpected response from API:"\
                                       "status #{response.status}"\
                                       "body #{response.body}"\
                                       "request #{URL}/#{postcode_param(postcode)}/")
      end
      Hash.from_xml(response.body)
    rescue Faraday::Error::TimeoutError
      raise ConstituencyApiError.new("Timeout after #{TIMEOUT} seconds")
    rescue Faraday::Error => e
      raise ConstituencyApiError.new("Network error - #{e}")
    end

    def self.last_mp(constituency_hash)
      mps = parse_mps(constituency_hash)
      mps.sort_by {|mp| mp.start_date}.last
    end

    def self.parse_mps(response)
      return nil unless response["RepresentingMembers"]
      mps = response["RepresentingMembers"]["RepresentingMember"]
      Array.wrap(mps).map { |m| Mp.new(m["Member_Id"].to_i, m["Member"], m["StartDate"].to_date) }
    end

    def self.postcode_param(postcode)
      postcode.gsub(/\s+/, "")
    end
    private_class_method :parse_constituencies, :call_api, :postcode_param
  end
end

