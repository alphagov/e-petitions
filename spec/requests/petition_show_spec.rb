require 'rails_helper'
require_relative 'api_request_helpers'

RSpec.describe 'API request to show a petition', type: :request, show_exceptions: true do
  include ApiRequestHelpers

  def make_successful_request(petition, params = {})
    get petition_url(petition, {format: 'json'}.merge(params))
    expect(response).to be_success
  end

  before do
    FactoryGirl.create(:location, :gb)
  end

  let(:petition) { FactoryGirl.create :open_petition }

  describe "format" do
    it "responds to JSON" do
      make_successful_request petition
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

    it 'includes signatures_by_country' do
      FactoryGirl.create(:location, code: 'FR')
      FactoryGirl.create(:location, code: 'DE')
      FactoryGirl.create(:pending_signature, petition: petition, location_code: 'FR').validate!
      FactoryGirl.create(:pending_signature, petition: petition, location_code: 'DE').validate!
      FactoryGirl.create(:pending_signature, petition: petition, location_code: 'GB').validate!
      FactoryGirl.create(:pending_signature, petition: petition, location_code: 'GB').validate!
      FactoryGirl.create(:pending_signature, petition: petition, location_code: 'FR').validate!

      make_successful_request petition


      assert_serialized_signatures_by_country petition, json['data']['attributes']
      fr_data = json['data']['attributes']['signatures_by_country'].detect { |sigs| sigs['code'] == 'FR' }
      expect(fr_data['signature_count']).to eq 2

      de_data = json['data']['attributes']['signatures_by_country'].detect { |sigs| sigs['code'] == 'DE' }
      expect(de_data['signature_count']).to eq 1

      gb_data = json['data']['attributes']['signatures_by_country'].detect { |sigs| sigs['code'] == 'GB' }
      expect(gb_data['signature_count']).to eq 3
    end
  end
end

