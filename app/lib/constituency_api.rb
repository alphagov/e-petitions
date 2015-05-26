# Or wrap things up in your own class
class ConstituencyApi

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

  
  include HTTParty
  base_uri 'data.parliament.uk/membersdataplatform/services/mnis/Constituencies'
  default_timeout 10

  def constituencies(postcode)
    response = call_api(postcode)
    parse_constituencies(response)
  end

  private
  
  def parse_constituencies(response)
    return [] unless response["Constituencies"]

    constituencies = response["Constituencies"]["Constituency"]
    if constituencies.kind_of?(Array)
      parse_multiple_constituencies(constituencies)
    else
      parse_constituency(constituencies)
    end
  end

  def parse_multiple_constituencies(constituencies)
    constituencies.map { |c| Constituency.new(c["Name"]) }
  end

  def parse_constituency(constituency)
    [Constituency.new(constituency["Name"])]
  end
  
  def call_api(postcode)
    response = self.class.get("/#{postcode_param(postcode)}/")
    raise ConstituencyApiError.new('Unexpected response') unless response.code == 200
    response.parsed_response
  rescue Timeout::Error
    raise ConstituencyApiError.new('Timeout after 10 seconds')
  end

  def postcode_param(postcode)
    postcode.gsub(/\s+/, "")
  end
end

