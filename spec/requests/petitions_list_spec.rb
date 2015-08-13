require 'rails_helper'
require_relative 'api_request_helpers'

RSpec.describe 'API request to list petitions', type: :request, show_exceptions: true do
  include ApiRequestHelpers

  def make_successful_request(params = {})
    get petitions_url({format: 'json'}.merge(params))
    expect(response).to be_success
  end

  describe "format" do
    it "responds to JSON" do
      make_successful_request
    end

    it "does not respond to XML" do
      get petitions_url(format: 'xml')
      expect(response.status).to eq(500)
    end
  end

  describe "links" do
    before do
      FactoryGirl.create_list :open_petition, 3
    end

    it "returns a link to itself" do
      make_successful_request

      expect(json["links"]).to include({"self" => petitions_url(format: 'json')})
    end

    it "returns a link to the first page of results" do
      make_successful_request count: 2

      expect(json["links"]).to include({"first" => petitions_url(count: 2, format: 'json')})
    end

    it "returns a link to the last page of results" do
      make_successful_request count: 2

      expect(json["links"]).to include({"last" => petitions_url(count: 2, page: 2, format: 'json')})
    end

    it "returns a link to the next page of results if there is one" do
      make_successful_request count: 2

      expect(json["links"]).to include({"next" => petitions_url(count: 2 ,page: 2, format: 'json')})
    end

    it "returns a link to the previous page of results if there is one" do
      make_successful_request count: 2, page: 2

      expect(json["links"]).to include({"prev" => petitions_url(count: 2, format: 'json')})
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
      FactoryGirl.create_list :open_petition, 3

      # reload petitions to get the expected ordering
      petitions = Petition.order("signature_count DESC, created_at DESC")

      make_successful_request

      expect(json["data"].length).to eq(3)
      assert_serialized_petition petitions.first, json["data"].first
      assert_serialized_petition petitions.second, json["data"].second
      assert_serialized_petition petitions.third, json["data"].third
    end

    it "includes a link to each petitions details" do
      petition = FactoryGirl.create :open_petition

      make_successful_request

      expect(json["data"][0]["links"]).to be_a Hash
      expect(json["data"][0]["links"]).to include("self" => petition_url(petition, format: 'json'))
    end

    it "includes the creator_name field for open petitions" do
      petition = FactoryGirl.create :open_petition

      make_successful_request

      expect(json["data"][0]["attributes"]).to include("creator_name" => petition.creator_signature.name)
    end

    (Petition::VISIBLE_STATES - Array(Petition::OPEN_STATE)).each do |state_name|
      it "does not include the creator_name field for #{state_name} petitions" do
        petition = FactoryGirl.create "#{state_name}_petition".to_sym

        make_successful_request

        expect(json["data"][0]["attributes"]).not_to include("creator_name" => petition.creator_signature.name)
      end
    end

    it "includes the rejection section for rejected petitions" do
      petition = FactoryGirl.create :rejected_petition

      make_successful_request

      assert_serialized_rejection petition, json["data"][0]["attributes"]
    end

    it "includes the government_response section for petitions with a government_response" do
      petition = FactoryGirl.create :responded_petition

      make_successful_request

      assert_serialized_government_response petition, json["data"][0]["attributes"]
    end

    it "includes the debate section for petitions that have been debated" do
      petition = FactoryGirl.create :debated_petition

      make_successful_request

      assert_serialized_debate petition, json["data"][0]["attributes"]
    end
  end
end

