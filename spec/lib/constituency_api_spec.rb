require 'rails_helper'
require 'webmock/rspec'

describe ConstituencyApi do

  describe "#constituencies" do
    let(:api) { ConstituencyApi.new }
    let(:constituency_array_1) { [ConstituencyApi::Constituency.new("Islington South and Finsbury")] }
    let(:constituency_array_2) { [ConstituencyApi::Constituency.new("Hackney North and Stoke Newington"),
                                  ConstituencyApi::Constituency.new("Hackney South and Shoreditch"),
                                  ConstituencyApi::Constituency.new("Holborn and St Pancras"),
                                  ConstituencyApi::Constituency.new("Islington North"),
                                  ConstituencyApi::Constituency.new("Islington South and Finsbury")] }

    it "returns an empty array for invalid postcode" do
      VCR.use_cassette "SW14 9RQ" do
        expect(api.constituencies("SW14 9RQ")).to eq []
      end
    end

    it "returns array for valid postcode" do
      VCR.use_cassette "N11TY" do
        expect(api.constituencies("N11TY")).to eq constituency_array_1
      end
    end

    it "returns array for valid postcode with whitespaces" do
      VCR.use_cassette "N1 1TY " do
        expect(api.constituencies("N1 1TY ")).to eq constituency_array_1
      end
    end

    it "returns array for valid postcode with lowercase" do
      VCR.use_cassette "n11ty_lowercase" do
        expect(api.constituencies("n11ty")).to eq constituency_array_1
      end
    end

    it "returns an array with multiple entries" do
      VCR.use_cassette "N1" do
        expect(api.constituencies("N1")).to eq constituency_array_2
      end
    end

    it "handles timeout errors" do
      stub_request(:any, /.*data.parliament.uk.*/).to_timeout
      expect{ api.constituencies("N1").count }.to raise_error(ConstituencyApi::ConstituencyApiError)
    end

    it "handles unexpected response" do
      VCR.use_cassette "N1_status_500" do
        expect{ api.constituencies("N1").count }.to raise_error(ConstituencyApi::ConstituencyApiError)
      end
    end
  end
end
