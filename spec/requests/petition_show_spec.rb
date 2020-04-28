require 'rails_helper'

RSpec.describe "API request to show a petition", type: :request, show_exceptions: true do
  let(:petition) { FactoryBot.create :open_petition, committee_note: "This petition action was found to be false" }
  let(:attributes) { json["data"]["attributes"] }

  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  describe "format" do
    it "responds to JSON" do
      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get "/petitions/#{petition.id}.json"

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to XML" do
      get "/petitions/#{petition.id}.xml"
      expect(response.status).to eq(406)
    end
  end

  describe "links" do
    let(:links) { json["links"] }

    it "returns a link to itself" do
      get "/petitions/#{petition.id}.json"

      expect(response).to be_successful
      expect(links).to include("self" => "https://petitions.senedd.wales/petitions/#{petition.id}.json")
    end
  end

  describe "data" do
    it "returns the petition with the expected fields" do
      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "action" => a_string_matching(petition.action),
          "background" => a_string_matching(petition.background),
          "additional_details" => a_string_matching(petition.additional_details),
          "committee_note" => a_string_matching(petition.committee_note),
          "state" => a_string_matching(petition.state),
          "signature_count" => eq_to(petition.signature_count),
          "opened_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "created_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "updated_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
        )
      )
    end

    it "returns the closed_at timestamp if the petition is closed" do
      petition = FactoryBot.create :closed_petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "state" => "closed",
          "closed_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
        )
      )
    end

    it "returns the completed_at timestamp date if the petition is completed" do
      petition = FactoryBot.create :completed_petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "state" => "completed",
          "completed_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
        )
      )
    end

    it "returns the archived_at timestamp date if the petition is archived" do
      petition = FactoryBot.create :archived_petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "state" => "completed",
          "archived_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
        )
      )
    end

    it "returns the submitted_on date if the petition was submitted on paper" do
      petition = FactoryBot.create :paper_petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "submitted_on_paper" => true,
          "submitted_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z])
        )
      )
    end

    it "doesn't include the rejection section for non-rejected petitions" do
      petition = FactoryBot.create :open_petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "rejected_at" => nil,
          "rejection" => nil
        )
      )
    end

    it "includes the rejection section for rejected petitions" do
      petition = \
        FactoryBot.create :rejected_petition,
          rejection_code: "duplicate",
          rejection_details: "This is a duplication of another petition"

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

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

    it "includes the date and time at which the thresholds were reached" do
      petition = \
        FactoryBot.create :open_petition,
          moderation_threshold_reached_at: 1.month.ago,
          referral_threshold_reached_at: 1.weeks.ago,
          debate_threshold_reached_at: 1.day.ago

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "moderation_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "referral_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "debate_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
        )
      )
    end

    it "includes the date and time at which the petition was referred" do
      petition = FactoryBot.create :referred_petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "referred_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
        )
      )
    end

    it "includes the date when a petition is scheduled for a debate" do
      petition = FactoryBot.create :scheduled_debate_petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "scheduled_debate_date" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z])
        )
      )
    end

    it "includes the debate section for petitions that have been debated" do
      petition = \
        FactoryBot.create :debated_petition,
          debated_on: 1.day.ago,
          overview: "What happened in the debate",
          transcript_url: "https://record.assembly.wales/Plenary/5667#A51756",
          video_url: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
          debate_pack_url: "http://www.senedd.assembly.wales/ieListDocuments.aspx?CId=401&MId=5667"

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "debate_outcome_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "debate" => a_hash_including(
            "debated_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
            "overview" => "What happened in the debate",
            "transcript_url" => "https://record.assembly.wales/Plenary/5667#A51756",
            "video_url" => "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
            "debate_pack_url" => "http://www.senedd.assembly.wales/ieListDocuments.aspx?CId=401&MId=5667"
          )
        )
      )
    end

    it "includes the signatures by constituency data" do
      petition = FactoryBot.create :open_petition

      FactoryBot.create :constituency, :cardiff_south_and_penarth
      FactoryBot.create :constituency, :swansea_west

      FactoryBot.create :constituency_petition_journal, constituency_id: "W09000043", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "W09000019", signature_count: 456, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "signatures_by_constituency" => a_collection_containing_exactly(
            {
              "id" => "W09000019",
              "name" => "Swansea West",
              "signature_count" => 456
            },
            {
              "id" => "W09000043",
              "name" => "Cardiff South and Penarth",
              "signature_count" => 123
            }
          )
        )
      )
    end

    it "doesn't include the signatures by constituency data in rejected petitions" do
      petition = FactoryBot.create :rejected_petition

      FactoryBot.create :constituency, :cardiff_south_and_penarth
      FactoryBot.create :constituency, :swansea_west

      FactoryBot.create :constituency_petition_journal, constituency_id: "W09000043", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "W09000019", signature_count: 456, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes.keys).not_to include("signatures_by_constituency")
    end

    it "includes the signatures by country data" do
      petition = FactoryBot.create :open_petition

      FactoryBot.create :country_petition_journal, location_code: "GB-WLS", signature_count: 123456, petition: petition
      FactoryBot.create :country_petition_journal, location_code: "FR", signature_count: 789, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "signatures_by_country" => a_collection_containing_exactly(
            {
              "name" => "Wales",
              "code" => "GB-WLS",
              "signature_count" => 123456
            },
            {
              "name" => "France",
              "code" => "FR",
              "signature_count" => 789
            }
          )
        )
      )
    end

    it "doesn't include the signatures by country data in rejected petitions" do
      petition = FactoryBot.create :rejected_petition

      FactoryBot.create :country_petition_journal, location_code: "GB-WLS", signature_count: 123456, petition: petition
      FactoryBot.create :country_petition_journal, location_code: "FR", signature_count: 789, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes.keys).not_to include("signatures_by_country")
    end

    it "includes the signatures by region data" do
      petition = FactoryBot.create :open_petition

      FactoryBot.create :constituency, :cardiff_south_and_penarth
      FactoryBot.create :constituency, :swansea_west

      FactoryBot.create :constituency_petition_journal, constituency_id: "W09000043", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "W09000019", signature_count: 456, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "signatures_by_region" => a_collection_containing_exactly(
            {
              "id" => "W10000007",
              "name" => "South Wales Central",
              "signature_count" => 123
            },
            {
              "id" => "W10000009",
              "name" => "South Wales West",
              "signature_count" => 456
            }
          )
        )
      )
    end

    it "doesn't include the signatures by constituency data in rejected petitions" do
      petition = FactoryBot.create :rejected_petition

      FactoryBot.create :constituency, :cardiff_south_and_penarth
      FactoryBot.create :constituency, :swansea_west

      FactoryBot.create :constituency_petition_journal, constituency_id: "W09000043", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "W09000019", signature_count: 456, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes.keys).not_to include("signatures_by_region")
    end
  end
end
