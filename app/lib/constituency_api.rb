module ConstituencyApi
  ConstituencyApiError = Class.new(RuntimeError)

  class Constituency < Struct.new(:name)
  end
  
  class Client
    include Faraday
    URL = 'http://data.parliament.uk/membersdataplatform/services/mnis/Constituencies'
    TIMEOUT = 10
    
    def self.constituencies(postcode)
      response = call_api(postcode)
      parse_constituencies(response)
    end
    
    
    def self.parse_constituencies(response)
      return [] unless response["Constituencies"]
      constituencies = response["Constituencies"]["Constituency"]
      Array.wrap(constituencies).map { |c| Constituency.new(c["Name"]) }
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
    rescue Faraday::TimeoutError
      raise ConstituencyApiError.new("Timeout after #{TIMEOUT} seconds")
    end
    
    def self.postcode_param(postcode)
      postcode.gsub(/\s+/, "")
    end
    private_class_method :parse_constituencies, :call_api, :postcode_param
  end
end


