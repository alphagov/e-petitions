module ConstituencyApiHelper
  def stub_api_request_for(postcode)
    stub_request(:get, api_url(postcode))
  end

  def stub_any_api_request
    stub_request(:get, %r[http://data.parliament.uk.*])
  end

  def api_response(status, body = "no_results", &block)
    status = Rack::Utils.status_code(status)
    headers = { "Content-Type" => "application/xml" }

    if block_given?
      body = block.call
    else
      body = File.read(Rails.root.join("spec", "fixtures", "constituency_api", "#{body}.xml"))
    end

    { status: status, headers: headers, body: body }
  end

  def api_url(postcode)
    "http://data.parliament.uk/membersdataplatform/services/mnis/Constituencies/#{postcode}/"
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(ConstituencyApiHelper)

    config.before do
      stub_api_request_for("SW1A1AA").to_return(api_response(:ok, "london_and_westminster"))
      stub_api_request_for("SW149RQ").to_return(api_response(:ok, "no_results"))
    end
  end
end
