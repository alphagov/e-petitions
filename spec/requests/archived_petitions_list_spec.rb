require 'rails_helper'

RSpec.describe "API request to list archived petitions", type: :request, show_exceptions: true do
  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  before do
    FactoryBot.create(:parliament, :archived)
  end

  describe "format" do
    it "responds to JSON" do
      get "/archived/petitions.json"
      expect(response).to be_success
    end

    it "sets CORS headers" do
      get "/archived/petitions.json"

      expect(response).to be_success
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to XML" do
      get "/archived/petitions.xml"
      expect(response.status).to eq(406)
    end
  end

  describe "links" do
    let(:links) { json["links"] }

    before do
      FactoryBot.create_list :archived_petition, 3
    end

    it "returns a link to itself" do
      get "/archived/petitions.json"

      expect(response).to be_success
      expect(links).to include("self" => "https://petition.parliament.uk/archived/petitions.json")
    end

    it "returns a link to the first page of results" do
      get "/archived/petitions.json?count=2"

      expect(response).to be_success
      expect(links).to include("first" => "https://petition.parliament.uk/archived/petitions.json?count=2")
    end

    it "returns a link to the last page of results" do
      get "/archived/petitions.json?count=2"

      expect(response).to be_success
      expect(links).to include("last" => "https://petition.parliament.uk/archived/petitions.json?count=2&page=2")
    end

    it "returns a link to the next page of results if there is one" do
      get "/archived/petitions.json?count=2"

      expect(response).to be_success
      expect(links).to include("next" => "https://petition.parliament.uk/archived/petitions.json?count=2&page=2")
    end

    it "returns a link to the previous page of results if there is one" do
      get "/archived/petitions.json?count=2&page=2"

      expect(response).to be_success
      expect(links).to include("prev" => "https://petition.parliament.uk/archived/petitions.json?count=2")
    end

    it "returns no link to the previous page of results when on the first page of results" do
      get "/archived/petitions.json?count=22"

      expect(response).to be_success
      expect(links).to include("prev" => nil)
    end

    it "returns no link to the next page of results when on the last page of results" do
      get "/archived/petitions.json?count=2&page=2"

      expect(response).to be_success
      expect(links).to include("next" => nil)
    end

    it "returns the last link == first link for empty results" do
      get "/archived/petitions.json?count=2&page=2&state=rejected"

      expect(response).to be_success
      expect(links).to include("last" => "https://petition.parliament.uk/archived/petitions.json?count=2&state=rejected")
    end

    it "returns previous page link == last link when paging off the end of the results" do
      get "/archived/petitions.json?count=2&page=3&state=rejected"

      expect(response).to be_success
      expect(links).to include("prev" => "https://petition.parliament.uk/archived/petitions.json?count=2&state=rejected")
    end
  end

  describe "data" do
    let(:data) { json["data"] }

    it "returns an empty response if no petitions are public" do
      get "/archived/petitions.json"

      expect(response).to be_success
      expect(data).to be_empty
    end

    it "returns a list of serialized petitions in the expected order" do
      petition_1 = FactoryBot.create :archived_petition, signature_count: 100
      petition_2 = FactoryBot.create :archived_petition, signature_count: 300
      petition_3 = FactoryBot.create :archived_petition, signature_count: 200

      get "/archived/petitions.json"
      expect(response).to be_success

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including("attributes" => a_hash_including("action" => petition_2.action)),
          a_hash_including("attributes" => a_hash_including("action" => petition_3.action)),
          a_hash_including("attributes" => a_hash_including("action" => petition_1.action))
        )
      )
    end

    it "includes a link to each petitions details" do
      petition = FactoryBot.create :archived_petition

      get "/archived/petitions.json"
      expect(response).to be_success

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "links" => a_hash_including(
              "self" => "https://petition.parliament.uk/archived/petitions/#{petition.id}.json"
            )
          )
        )
      )
    end

    it "includes the rejection section for rejected petitions" do
      petition = \
        FactoryBot.create :archived_petition, :rejected,
          rejection_code: "duplicate",
          rejection_details: "This is a duplication of another petition"

      get "/archived/petitions.json"
      expect(response).to be_success

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "attributes" => a_hash_including(
              "rejection" => a_hash_including(
                "code" => "duplicate",
                "details" => "This is a duplication of another petition"
              )
            )
          )
        )
      )
    end

    it "includes the government_response section for petitions with a government_response" do
      petition = \
        FactoryBot.create :archived_petition, :response,
          response_summary: "Summary of what the government said",
          response_details: "Details of what the government said"

      get "/archived/petitions.json"
      expect(response).to be_success

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "attributes" => a_hash_including(
              "government_response" => a_hash_including(
                "responded_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
                "summary" => "Summary of what the government said",
                "details" => "Details of what the government said"
              )
            )
          )
        )
      )
    end

    it "includes the debate section for petitions that have been debated" do
      petition = \
        FactoryBot.create :archived_petition, :debated,
          debated_on: 1.day.ago,
          overview: "What happened in the debate",
          transcript_url: "http://www.publications.parliament.uk/pa/cm201212/cmhansrd/cm120313/debtext/120313-0001.htm#12031360000001",
          video_url: "http://parliamentlive.tv/event/index/da084e18-0e48-4d0a-9aa5-be27f57d5a71?in=16:31:00",
          debate_pack_url: "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2014-1234"

      get "/archived/petitions.json"
      expect(response).to be_success

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "attributes" => a_hash_including(
              "debate" => a_hash_including(
                "debated_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
                "overview" => "What happened in the debate",
                "transcript_url" => "http://www.publications.parliament.uk/pa/cm201212/cmhansrd/cm120313/debtext/120313-0001.htm#12031360000001",
                "video_url" => "http://parliamentlive.tv/event/index/da084e18-0e48-4d0a-9aa5-be27f57d5a71?in=16:31:00",
                "debate_pack_url" => "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2014-1234"
              )
            )
          )
        )
      )
    end
  end
end
