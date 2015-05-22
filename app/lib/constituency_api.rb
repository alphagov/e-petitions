# Or wrap things up in your own class
class ConstituencyApi
  include HTTParty
  base_uri 'data.parliament.uk/membersdataplatform/services/mnis/Constituencies'

  #handle postcode validation - as in regex in signer detail validation?
  
  def constituency(postcode)
    response = self.class.get("/#{postcode.gsub(/\s+/, "")}")
    begin
      response.parsed_response["Constituencies"]["Constituency"]["Name"]
    rescue
      return nil
    end
  end
end
