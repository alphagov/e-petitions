# Or wrap things up in your own class
class ConstituencyApi
  include Faraday
  
  URL = 'http://data.parliament.uk/membersdataplatform/services/mnis/Constituencies'

  ConstituencyApiError = Class.new(RuntimeError)
  
  class Constituency
    attr_accessor :name
    
    def initialize(name)
      self.name = name
    end
    
    def ==(another_constituency)
      self.name == another_constituency.name
    end
  end

  def self.constituencies(postcode)
    response = call_api(postcode)
    parse_constituencies(response)
  end

  private
  
  def self.parse_constituencies(response)
    return [] unless response["Constituencies"]
    constituencies = response["Constituencies"]["Constituency"]
    Array.wrap(constituencies).map { |c| Constituency.new(c["Name"]) }
  end
  
  def self.call_api(postcode)
    response = Faraday.new(URL).get("#{postcode_param(postcode)}/") do |req|
      req.options[:timeout] = 10
      req.options[:open_timeout] = 10
    end
    raise ConstituencyApiError.new('Unexpected response') unless response.status == 200
    Hash.from_xml(response.body)
  rescue Faraday::TimeoutError
    raise ConstituencyApiError.new('Timeout after 10 seconds')
  end

  def self.postcode_param(postcode)
    postcode.gsub(/\s+/, "")
  end
end

