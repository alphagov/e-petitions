require 'rails_helper'
require_relative 'api_request_helpers'

RSpec.describe 'API request to show a petition', type: :request, show_exceptions: true do
  include ApiRequestHelpers

  def make_successful_request(petition, params = {})
    get petition_url(petition, {format: 'json'}.merge(params))
    expect(response).to be_success
  end

  let(:petition) { FactoryGirl.create :open_petition }
  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  describe "format" do
    it "responds to JSON" do
      make_successful_request petition
    end

    it "sets CORS headers" do
      get petition_url(petition, format: 'json')
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to XML" do
      get petition_url(petition, format: 'xml')
      expect(response.status).to eq(406)
    end
  end

  describe "links" do
    it "returns a link to itself" do
      make_successful_request petition

      expect(json["links"]).to include({"self" => petition_url(petition, format: 'json')})
    end
  end

  describe "data" do
    it "includes the creator_name field for open petitions" do
      petition = FactoryGirl.create :open_petition

      make_successful_request petition

      expect(json["data"]["attributes"]).to include("creator_name" => petition.creator_signature.name)
    end

    (Petition::VISIBLE_STATES - Array(Petition::OPEN_STATE)).each do |state_name|
      let!(:petition) { FactoryGirl.create "#{state_name}_petition".to_sym }

      it "does not include the creator_name field for #{state_name} petitions" do
        make_successful_request petition

        expect(json["data"]["attributes"]).not_to include("creator_name" => petition.creator_signature.name)
      end
    end

    it "returns the petition with the expected fields" do
      make_successful_request petition

      expect(json["data"]).to be_a Hash
      assert_serialized_petition petition, json["data"]
    end

    it "includes the rejection section for rejected petitions" do
      rejected_petition = FactoryGirl.create :rejected_petition

      make_successful_request rejected_petition

      assert_serialized_rejection rejected_petition, json["data"]["attributes"]
    end

    it "includes the government_response section for petitions with a government_response" do
      responded_petition = FactoryGirl.create :responded_petition

      make_successful_request responded_petition

      assert_serialized_government_response responded_petition, json["data"]["attributes"]
    end

    it "includes the debate section for petitions that have been debated" do
      debated_petition = FactoryGirl.create :debated_petition

      make_successful_request debated_petition

      assert_serialized_debate debated_petition, json["data"]["attributes"]
    end

    context "with trending petition journals" do
      let(:time) { Time.parse("1 Jan 2017 05:00:00 GMT") }
      let(:date) { Date.today }

      around do |example|
        travel_to(time) { example.run }
      end

      before do
        FactoryGirl.create(
          :trending_petition_journal,
          hour_1_signature_count: 1,
          hour_4_signature_count: 2,
          date: date,
          petition: petition
        )
      end

      it "returns the expected signatures by hour" do
        make_successful_request petition

        expect(json["data"]["attributes"]["signatures_by_hour"]).to eq(
          [
            { starts_at: "2017-01-01T00:00:00.000Z", ends_at: "2017-01-01T01:00:00.000Z", signature_count: 0 },
            { starts_at: "2017-01-01T01:00:00.000Z", ends_at: "2017-01-01T02:00:00.000Z", signature_count: 1 },
            { starts_at: "2017-01-01T02:00:00.000Z", ends_at: "2017-01-01T03:00:00.000Z", signature_count: 0 },
            { starts_at: "2017-01-01T03:00:00.000Z", ends_at: "2017-01-01T04:00:00.000Z", signature_count: 0 },
            { starts_at: "2017-01-01T04:00:00.000Z", ends_at: "2017-01-01T05:00:00.000Z", signature_count: 2 },
            { starts_at: "2017-01-01T05:00:00.000Z", ends_at: "2017-01-01T06:00:00.000Z", signature_count: 0 }
          ].map(&:stringify_keys)
        )
      end
    end
  end
end
