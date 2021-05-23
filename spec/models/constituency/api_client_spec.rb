require 'rails_helper'

RSpec.describe Constituency::ApiClient, type: :model do
  let(:client) { described_class.new }

  describe "#call" do
    it "removes whitespace from the postcode" do
      stub = stub_api_request_for("N11TY")
      client.call("N1 1TY")
      expect(stub).to have_been_requested
    end

    it "upcases the postcode" do
      stub = stub_api_request_for("N11TY")
      client.call("n11ty")
      expect(stub).to have_been_requested
    end

    it "escapes the postcode" do
      stub = stub_api_request_for("N1")
      client.call("N£1")
      expect(stub).to have_been_requested
    end
  end
end
