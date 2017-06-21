require 'rails_helper'
require_relative 'api_request_helpers'

RSpec.describe 'API request to show an archived petition', type: :request, show_exceptions: true do
  include ApiRequestHelpers

  def make_successful_request(petition, params = {})
    get archived_petition_url(petition, {format: 'json'}.merge(params))
    expect(response).to be_success
  end

  let(:petition) { FactoryGirl.create :archived_petition }
  let(:attributes) { json["data"]["attributes"] }

  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  describe "format" do
    it "responds to JSON" do
      make_successful_request petition
    end

    it "sets CORS headers" do
      get archived_petition_url(petition, format: 'json')
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to XML" do
      get archived_petition_url(petition, format: 'xml')
      expect(response.status).to eq(406)
    end
  end

  describe "links" do
    it "returns a link to itself" do
      make_successful_request petition

      expect(json["links"]).to include({"self" => archived_petition_url(petition, format: 'json')})
    end
  end

  describe "data" do
    it "returns the petition with the expected fields" do
      make_successful_request petition

      expect(json["data"]).to be_a(Hash)
      expect(attributes["action"]).to eq(petition.action)
      expect(attributes["background"]).to eq(petition.background)
      expect(attributes["additional_details"]).to eq(petition.additional_details)
      expect(attributes["state"]).to eq(petition.state)
      expect(attributes["signature_count"]).to eq(petition.signature_count)
      expect(attributes["opened_at"]).to eq(timestampify petition.opened_at)
      expect(attributes["closed_at"]).to eq(timestampify petition.closed_at)
      expect(attributes["created_at"]).to eq(timestampify petition.created_at)
      expect(attributes["updated_at"]).to eq(timestampify petition.updated_at)
    end

    it "includes the rejection section for rejected petitions" do
      petition = FactoryGirl.create :archived_petition, :rejected

      make_successful_request petition

      expect(attributes["rejection"]).to be_a(Hash)
      expect(attributes["rejection"]["details"]).to eq(petition.reason_for_rejection)
    end

    it "includes the government_response section for petitions with a government_response" do
      petition = FactoryGirl.create :archived_petition, :response, response_summary: "Summary of what the government said", response_details: "Details of what the government said"

      make_successful_request petition

      expect(attributes["government_response"]).to be_a(Hash)
      expect(attributes["government_response"]["summary"]).to eq("Summary of what the government said")
      expect(attributes["government_response"]["details"]).to eq("Details of what the government said")
    end
  end
end
