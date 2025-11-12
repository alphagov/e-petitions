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
      expect(links).to include("self" => "https://petition.parliament.uk/petitions/#{petition.id}.json")
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
          "closed_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
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

    it "includes the government_response section for petitions with a government_response" do
      petition = \
        FactoryBot.create :responded_petition,
          response_summary: "Summary of what the government said",
          response_details: "Details of what the government said"

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

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
        FactoryBot.create :open_petition,
          moderation_threshold_reached_at: 1.month.ago,
          response_threshold_reached_at: 1.weeks.ago,
          debate_threshold_reached_at: 1.day.ago

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "moderation_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "response_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "debate_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
        )
      )
    end

    it "includes the date when a petition is scheduled for a debate" do
      petition = FactoryBot.create :scheduled_debate_petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "debate_scheduled_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "scheduled_debate_date" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z])
        )
      )
    end

    it "includes the debate section for petitions that have been debated" do
      petition = \
        FactoryBot.create :debated_petition,
          debated_on: 1.day.ago,
          overview: "What happened in the debate",
          transcript_url: "http://www.publications.parliament.uk/pa/cm201212/cmhansrd/cm120313/debtext/120313-0001.htm#12031360000001",
          video_url: "http://parliamentlive.tv/event/index/da084e18-0e48-4d0a-9aa5-be27f57d5a71?in=16:31:00",
          debate_pack_url: "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2014-1234",
          public_engagement_url: "https://committees.parliament.uk/public-engagement",
          debate_summary_url: "https://ukparliament.shorthandstories.com/about-a-petition"

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "debate_outcome_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "debate" => a_hash_including(
            "debated_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
            "overview" => "What happened in the debate",
            "transcript_url" => "http://www.publications.parliament.uk/pa/cm201212/cmhansrd/cm120313/debtext/120313-0001.htm#12031360000001",
            "video_url" => "http://parliamentlive.tv/event/index/da084e18-0e48-4d0a-9aa5-be27f57d5a71?in=16:31:00",
            "debate_pack_url" => "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2014-1234",
            "public_engagement_url" => "https://committees.parliament.uk/public-engagement",
            "debate_summary_url" => "https://ukparliament.shorthandstories.com/about-a-petition",
          )
        )
      )
    end

    it "includes the departments data" do
      fco = FactoryBot.create :department, :fco
      dfid = FactoryBot.create :department, :dfid

      petition = \
        FactoryBot.create :open_petition,
          departments: [fco.id, dfid.id]

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "departments" => a_collection_containing_exactly(
            {
              "acronym" => "DfID",
              "name" => "Department for International Development",
              "url" => "https://www.gov.uk/government/organisations/department-for-international-development"
            },
            {
              "acronym" => "FCO",
              "name" => "Foreign and Commonwealth Office",
              "url" => "https://www.gov.uk/government/organisations/foreign-commonwealth-office"
            }
          )
        )
      )
    end

    it "includes the topics data" do
      topic = FactoryBot.create :topic, code: "covid-19", name: "COVID-19"

      petition = \
        FactoryBot.create :open_petition,
          topics: [topic.id]

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including("topics" => %w[covid-19])
      )
    end

    it "includes the signatures by constituency data" do
      petition = FactoryBot.create :open_petition

      FactoryBot.create :constituency, :coventry_north_east
      FactoryBot.create :constituency, :bethnal_green_and_bow

      FactoryBot.create :constituency_petition_journal, constituency_id: "3427", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "3320", signature_count: 456, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

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
      petition = FactoryBot.create :rejected_petition

      FactoryBot.create :constituency, :coventry_north_east
      FactoryBot.create :constituency, :bethnal_green_and_bow

      FactoryBot.create :constituency_petition_journal, constituency_id: "3427", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "3320", signature_count: 456, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes.keys).not_to include("signatures_by_constituency")
    end

    it "includes the signatures by country data" do
      petition = FactoryBot.create :open_petition

      gb = FactoryBot.create :location, name: "United Kingdom", code: "gb"
      fr = FactoryBot.create :location, name: "France", code: "fr"

      FactoryBot.create :country_petition_journal, location: gb, signature_count: 123456, petition: petition
      FactoryBot.create :country_petition_journal, location: fr, signature_count: 789, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

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
      petition = FactoryBot.create :rejected_petition

      gb = FactoryBot.create :location, name: "United Kingdom", code: "gb"
      fr = FactoryBot.create :location, name: "France", code: "fr"

      FactoryBot.create :country_petition_journal, location: gb, signature_count: 123456, petition: petition
      FactoryBot.create :country_petition_journal, location: fr, signature_count: 789, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes.keys).not_to include("signatures_by_country")
    end

    it "includes the signatures by region data" do
      petition = FactoryBot.create :open_petition

      FactoryBot.create :constituency, :coventry_north_east
      FactoryBot.create :constituency, :bethnal_green_and_bow

      FactoryBot.create :constituency_petition_journal, constituency_id: "3427", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "3320", signature_count: 456, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "signatures_by_region" => a_collection_containing_exactly(
            {
              "name" => "West Midlands",
              "ons_code" => "F",
              "signature_count" => 123
            },
            {
              "name" => "London",
              "ons_code" => "H",
              "signature_count" => 456
            }
          )
        )
      )
    end

    it "doesn't include the signatures by region data in rejected petitions" do
      petition = FactoryBot.create :rejected_petition

      FactoryBot.create :constituency, :coventry_north_east
      FactoryBot.create :constituency, :bethnal_green_and_bow

      FactoryBot.create :constituency_petition_journal, constituency_id: "3427", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "3320", signature_count: 456, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes.keys).not_to include("signatures_by_region")
    end

    it "includes related activity" do
      petition = FactoryBot.create :open_petition
      email_1  = FactoryBot.create :petition_email, petition: petition, subject: "Original Government Response", body: "This is the original government response", created_at: 1.day.ago
      email_2  = FactoryBot.create :petition_email, petition: petition, subject: "Debate Decision", body: "Petitions committee will debate this petition", created_at: 2.days.ago

      get "/petitions/#{petition.id}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "other_parliamentary_business" => a_collection_containing_exactly(
            {
              "subject" => "Debate Decision",
              "body" => "Petitions committee will debate this petition\n",
              "created_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
              "updated_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
            },
            {
              "subject" => "Original Government Response",
              "body" => "This is the original government response\n",
              "created_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
              "updated_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
            }
          )
        )
      )
    end
  end
end
