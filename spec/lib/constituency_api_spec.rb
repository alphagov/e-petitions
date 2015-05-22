require 'rails_helper'
require 'support/vcr_setup'

describe ConstituencyApi, :vcr => true do
  describe "#constituency" do
    let(:api) { ConstituencyApi.new }
    
    it "returns the constituency for concatenated postcode" do
      VCR.use_cassette "N11TY" do
        expect(api.constituency("N11TY")).to eq "Islington South and Finsbury"
      end
    end
    it "returns the constituency for postcode with whitespaces" do
      VCR.use_cassette "N1 1TY " do
        expect(api.constituency("N1 1TY ")).to eq "Islington South and Finsbury"
      end
    end
    it "returns nil for invalid postcode" do
      VCR.use_cassette "SW14 9RQ" do
        expect(api.constituency("SW14 9RQ")).to be_nil
      end
    end
    it "returns nil for too short postcode that would return several constituencies" do
      VCR.use_cassette "N1" do
        expect(api.constituency("N1")).to be_nil
      end
    end
  end
end
