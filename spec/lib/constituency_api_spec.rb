require 'rails_helper'

describe ConstituencyApi do

  describe "#constituencies" do
    let(:api) { ConstituencyApi::Client }
    let(:api_url) { "http://data.parliament.uk/membersdataplatform/services/mnis/Constituencies" }

    let(:constituency_array_1) { [ConstituencyApi::Constituency.new("Islington South and Finsbury")] }
    let(:constituency_array_2) { [ConstituencyApi::Constituency.new("Hackney North and Stoke Newington"),
                                  ConstituencyApi::Constituency.new("Hackney South and Shoreditch"),
                                  ConstituencyApi::Constituency.new("Holborn and St Pancras"),
                                  ConstituencyApi::Constituency.new("Islington North"),
                                  ConstituencyApi::Constituency.new("Islington South and Finsbury")] }
    let(:empty_body) {
      "<Constituencies/>"
    }
    let(:fake_body) {
      "<Constituencies>
        <Constituency><Name>Islington South and Finsbury</Name></Constituency>
       </Constituencies>"
    }
    let(:fake_body_multiple) {
      "<Constituencies>
        <Constituency><Name>Hackney North and Stoke Newington</Name></Constituency>
        <Constituency><Name>Hackney South and Shoreditch</Name></Constituency>
        <Constituency><Name>Holborn and St Pancras</Name></Constituency>
        <Constituency><Name>Islington North</Name></Constituency>
        <Constituency><Name>Islington South and Finsbury</Name></Constituency>
       </Constituencies>"
    }
    
    it "returns an empty array for invalid postcode" do
      stub_request(:get, "#{ api_url }/SW149RQ/").to_return(status: 200, body: empty_body)
      expect(api.constituencies("SW14 9RQ")).to eq []
    end
    
    it "returns array for valid postcode" do
      stub_request(:get, "#{ api_url }/N11TY/").to_return(status: 200, body: fake_body)
      expect(api.constituencies("N11TY")).to eq constituency_array_1
    end

    it "returns array for valid postcode with whitespaces" do
      stub_request(:get, "#{ api_url }/N11TY/").to_return(status: 200, body: fake_body)
      expect(api.constituencies("N1 1TY ")).to eq constituency_array_1
    end

    it "returns array for valid postcode with lowercase" do
      stub_request(:get, "#{ api_url }/n11ty/").to_return(status: 200, body: fake_body)
      expect(api.constituencies("n11ty")).to eq constituency_array_1
    end

    it "returns an array with multiple entries" do
      stub_request(:get, "#{ api_url }/N1/").to_return(status: 200, body: fake_body_multiple)
      expect(api.constituencies("N1")).to eq constituency_array_2
    end

    it "handles timeout errors" do
      stub_request(:any, /.*data.parliament.uk.*/).to_timeout
      expect{ api.constituencies("N1").count }.to raise_error(ConstituencyApi::ConstituencyApiError)
    end

    it "handles connection failed errors" do
      stub_request(:any, /.*data.parliament.uk.*/).to_raise(Faraday::Error::ConnectionFailed)
      expect{ api.constituencies("N1").count }.to raise_error(ConstituencyApi::ConstituencyApiError)
    end
    
    it "handles resource not found errors" do
      stub_request(:any, /.*data.parliament.uk.*/).to_raise(Faraday::Error::ResourceNotFound)
      expect{ api.constituencies("N1").count }.to raise_error(ConstituencyApi::ConstituencyApiError)
    end
    
    it "handles unexpected response" do
      stub_request(:get, "#{ api_url }/N1/").to_return(status: 500, body: fake_body)
      expect{ api.constituencies("N1").count }.to raise_error(ConstituencyApi::ConstituencyApiError)
    end
  end
end
