require 'rails_helper'

RSpec.describe "API request to show an archived petition", type: :request, show_exceptions: true do
  let(:petition) { FactoryBot.create :archived_petition }
  let(:attributes) { json["data"]["attributes"] }

  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  describe "format" do
    it "responds to JSON" do
      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success
    end

    it "sets CORS headers" do
      get "/archived/petitions/#{petition.id}.json"

      expect(response).to be_success
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to XML" do
      get "/archived/petitions/#{petition.id}.xml"
      expect(response.status).to eq(406)
    end

    context "when accessing the old url" do
      before do
        get "/petitions/#{petition.id}.json"
      end

      it "redirects to the archive url" do
        expect(response).to redirect_to("/archived/petitions/#{petition.id}.json")
        expect(access_control_allow_origin).to eq('*')
        expect(access_control_allow_methods).to eq('GET')
        expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
      end
    end
  end

  describe "links" do
    let(:links) { json["links"] }

    it "returns a link to itself" do
      get "/archived/petitions/#{petition.id}.json"

      expect(response).to be_success
      expect(links).to include("self" => "https://petition.parliament.uk/archived/petitions/#{petition.id}.json")
    end
  end

  describe "data" do
    it "returns the petition with the expected fields" do
      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "action" => a_string_matching(petition.action),
          "background" => a_string_matching(petition.background),
          "additional_details" => a_string_matching(petition.additional_details),
          "state" => a_string_matching(petition.state),
          "signature_count" => eq_to(petition.signature_count),
          "opened_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "closed_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "created_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "updated_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
        )
      )
    end

    it "includes the rejection section for rejected petitions" do
      petition = \
        FactoryBot.create :archived_petition, :rejected,
          rejection_code: "duplicate",
          rejection_details: "This is a duplication of another petition"

      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "rejected_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "rejection" => a_hash_including(
            "code" => "duplicate",
            "details" => "This is a duplication of another petition"
          )
        )
      )
    end

    it "includes the government_response section for petitions with a government_response" do
      petition = \
        FactoryBot.create :archived_petition, :response,
          response_summary: "Summary of what the government said",
          response_details: "Details of what the government said"

      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "government_response_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "government_response" => a_hash_including(
            "responded_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
            "summary" => "Summary of what the government said",
            "details" => "Details of what the government said",
            "created_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
            "updated_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
          )
        )
      )
    end

    it "includes the date and time at which the thresholds were reached" do
      petition = \
        FactoryBot.create :archived_petition,
          moderation_threshold_reached_at: 1.month.ago,
          response_threshold_reached_at: 1.weeks.ago,
          debate_threshold_reached_at: 1.day.ago

      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "moderation_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "response_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "debate_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
        )
      )
    end

    it "includes the date when a petition is scheduled for a debate" do
      petition = FactoryBot.create :archived_petition, :scheduled_for_debate

      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "scheduled_debate_date" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z])
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

      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "debate_outcome_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "debate" => a_hash_including(
            "debated_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
            "overview" => "What happened in the debate",
            "transcript_url" => "http://www.publications.parliament.uk/pa/cm201212/cmhansrd/cm120313/debtext/120313-0001.htm#12031360000001",
            "video_url" => "http://parliamentlive.tv/event/index/da084e18-0e48-4d0a-9aa5-be27f57d5a71?in=16:31:00",
            "debate_pack_url" => "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2014-1234"
          )
        )
      )
    end

    it "includes the signatures by constituency data" do
      FactoryBot.create :constituency, :coventry_north_east
      FactoryBot.create :constituency, :bethnal_green_and_bow

      petition = \
        FactoryBot.create :archived_petition,
          signatures_by_constituency: { 3427 => 123, 3320 => 456 }

      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "signatures_by_constituency" => a_collection_containing_exactly(
            {
              "name" => "Coventry North East",
              "ons_code" => "E14000649",
              "mp" => "Colleen Fletcher MP",
              "signature_count" => 123
            },
            {
              "name" => "Bethnal Green and Bow",
              "ons_code" => "E14000555",
              "mp" => "Rushanara Ali MP",
              "signature_count" => 456
            }
          )
        )
      )
    end

    it "doesn't include the signatures by constituency data in rejected petitions" do
      FactoryBot.create :constituency, :coventry_north_east
      FactoryBot.create :constituency, :bethnal_green_and_bow

      petition = \
        FactoryBot.create :archived_petition, :rejected,
          signatures_by_constituency: { 3427 => 123, 3320 => 456 }

      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes.keys).not_to include("signatures_by_constituency")
    end

    it "includes the signatures by country data" do
      FactoryBot.create :location, name: "United Kingdom", code: "gb"
      FactoryBot.create :location, name: "France", code: "fr"

      petition = \
        FactoryBot.create :archived_petition,
          signatures_by_country: { "gb" => 123456, "fr" => 789 }

      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "signatures_by_country" => a_collection_containing_exactly(
            {
              "name" => "United Kingdom",
              "code" => "gb",
              "signature_count" => 123456
            },
            {
              "name" => "France",
              "code" => "fr",
              "signature_count" => 789
            }
          )
        )
      )
    end

    it "doesn't include the signatures by country data in rejected petitions" do
      FactoryBot.create :location, name: "United Kingdom", code: "gb"
      FactoryBot.create :location, name: "France", code: "fr"

      petition = \
        FactoryBot.create :archived_petition, :rejected,
          signatures_by_country: { "gb" => 123456, "fr" => 789 }

      get "/archived/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes.keys).not_to include("signatures_by_country")
    end
  end
end
