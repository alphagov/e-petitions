require 'rails_helper'
require_relative 'api_request_helpers'

RSpec.describe 'API request to list archived petitions', type: :request, show_exceptions: true do
  include ApiRequestHelpers

  def make_successful_request(params = {})
    get archived_petitions_url({format: 'json'}.merge(params))
    expect(response).to be_success
  end

  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  before do
    FactoryGirl.create(:parliament, :archived)
  end

  describe "format" do
    it "responds to JSON" do
      make_successful_request
    end

    it "sets CORS headers" do
      get archived_petitions_url(format: 'json')
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to XML" do
      get archived_petitions_url(format: 'xml')
      expect(response.status).to eq(406)
    end
  end

  describe "links" do
    before do
      FactoryGirl.create_list :archived_petition, 3
    end

    it "returns a link to itself" do
      make_successful_request

      expect(json["links"]).to include({"self" => archived_petitions_url(format: 'json')})
    end

    it "returns a link to the first page of results" do
      make_successful_request count: 2

      expect(json["links"]).to include({"first" => archived_petitions_url(count: 2, format: 'json')})
    end

    it "returns a link to the last page of results" do
      make_successful_request count: 2

      expect(json["links"]).to include({"last" => archived_petitions_url(count: 2, page: 2, format: 'json')})
    end

    it "returns a link to the next page of results if there is one" do
      make_successful_request count: 2

      expect(json["links"]).to include({"next" => archived_petitions_url(count: 2 ,page: 2, format: 'json')})
    end

    it "returns a link to the previous page of results if there is one" do
      make_successful_request count: 2, page: 2

      expect(json["links"]).to include({"prev" => archived_petitions_url(count: 2, format: 'json')})
    end

    it "returns no link to the previous page of results when on the first page of results" do
      make_successful_request count: 2

      expect(json["links"]).to include({"prev" => nil})
    end

    it "returns no link to the next page of results when on the last page of results" do
      make_successful_request count: 2, page: 2

      expect(json["links"]).to include({"next" => nil})
    end

    it "returns the last link == first link for empty results" do
      make_successful_request count: 2, page: 2, state: 'rejected'

      expect(json["links"]).to include({"last" => json["links"]["first"]})
    end

    it "returns previous page link == last link when paging off the end of the results" do
      make_successful_request count: 2, page: 3, state: 'rejected'

      expect(json["links"]).to include({"prev" => json["links"]["last"]})
    end
  end

  describe "data" do
    it "returns an empty response if no petitions are public" do
      make_successful_request

      expect(json["data"]).to be_empty
    end

    it "returns a list of serialized petitions in the expected order" do
      petition_1 = FactoryGirl.create :archived_petition, signature_count: 100
      petition_2 = FactoryGirl.create :archived_petition, signature_count: 300
      petition_3 = FactoryGirl.create :archived_petition, signature_count: 200

      make_successful_request

      expect(json["data"].length).to eq(3)

      expect(json["data"][0]["attributes"]["action"]).to eq(petition_2.action)
      expect(json["data"][1]["attributes"]["action"]).to eq(petition_3.action)
      expect(json["data"][2]["attributes"]["action"]).to eq(petition_1.action)
    end

    it "includes a link to each petitions details" do
      petition = FactoryGirl.create :archived_petition

      make_successful_request

      expect(json["data"][0]["links"]).to be_a Hash
      expect(json["data"][0]["links"]).to include("self" => archived_petition_url(petition, format: 'json'))
    end

    it "includes the rejection section for rejected petitions" do
      petition = FactoryGirl.create :archived_petition, :rejected, rejection_code: "duplicate", rejection_details: "This is a duplication of another petition"

      make_successful_request

      expect(json["data"][0]["attributes"]["rejection"]).to be_a(Hash)
      expect(json["data"][0]["attributes"]["rejection"]["code"]).to eq("duplicate")
      expect(json["data"][0]["attributes"]["rejection"]["details"]).to eq("This is a duplication of another petition")
    end

    it "includes the government_response section for petitions with a government_response" do
      petition = FactoryGirl.create :archived_petition, :response, response_summary: "Summary of what the government said", response_details: "Details of what the government said"

      make_successful_request

      expect(json["data"][0]["attributes"]["government_response"]["summary"]).to eq("Summary of what the government said")
      expect(json["data"][0]["attributes"]["government_response"]["details"]).to eq("Details of what the government said")
    end
  end
end
