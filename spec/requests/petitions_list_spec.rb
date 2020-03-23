require 'rails_helper'

RSpec.describe "API request to list petitions", type: :request, show_exceptions: true do
  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  describe "format" do
    it "responds to JSON" do
      get "/petitions.json"
      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get "/petitions.json"

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to XML" do
      get "/petitions.xml"
      expect(response.status).to eq(406)
    end
  end

  describe "links" do
    let(:links) { json["links"] }

    before do
      FactoryBot.create_list :open_petition, 3
    end

    it "returns a link to itself" do
      get "/petitions.json"

      expect(response).to be_successful
      expect(links).to include("self" => "https://petitions.senedd.wales/petitions.json")
    end

    it "returns a link to the first page of results" do
      get "/petitions.json?count=2"

      expect(response).to be_successful
      expect(links).to include("first" => "https://petitions.senedd.wales/petitions.json?count=2")
    end

    it "returns a link to the last page of results" do
      get "/petitions.json?count=2"

      expect(response).to be_successful
      expect(links).to include("last" => "https://petitions.senedd.wales/petitions.json?count=2&page=2")
    end

    it "returns a link to the next page of results if there is one" do
      get "/petitions.json?count=2"

      expect(response).to be_successful
      expect(links).to include("next" => "https://petitions.senedd.wales/petitions.json?count=2&page=2")
    end

    it "returns a link to the previous page of results if there is one" do
      get "/petitions.json?count=2&page=2"

      expect(response).to be_successful
      expect(links).to include("prev" => "https://petitions.senedd.wales/petitions.json?count=2")
    end

    it "returns no link to the previous page of results when on the first page of results" do
      get "/petitions.json?count=22"

      expect(response).to be_successful
      expect(links).to include("prev" => nil)
    end

    it "returns no link to the next page of results when on the last page of results" do
      get "/petitions.json?count=2&page=2"

      expect(response).to be_successful
      expect(links).to include("next" => nil)
    end

    it "returns the last link == first link for empty results" do
      get "/petitions.json?count=2&page=2&state=rejected"

      expect(response).to be_successful
      expect(links).to include("last" => "https://petitions.senedd.wales/petitions.json?count=2&state=rejected")
    end

    it "returns previous page link == last link when paging off the end of the results" do
      get "/petitions.json?count=2&page=3&state=rejected"

      expect(response).to be_successful
      expect(links).to include("prev" => "https://petitions.senedd.wales/petitions.json?count=2&state=rejected")
    end
  end

  describe "data" do
    let(:data) { json["data"] }

    it "returns an empty response if no petitions are public" do
      get "/petitions.json"

      expect(response).to be_successful
      expect(data).to be_empty
    end

    it "returns a list of serialized petitions in the expected order" do
      petition_1 = FactoryBot.create :open_petition, signature_count: 100
      petition_2 = FactoryBot.create :open_petition, signature_count: 300
      petition_3 = FactoryBot.create :open_petition, signature_count: 200

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including("attributes" => a_hash_including("action" => petition_2.action)),
          a_hash_including("attributes" => a_hash_including("action" => petition_3.action)),
          a_hash_including("attributes" => a_hash_including("action" => petition_1.action))
        )
      )
    end

    it "includes a link to each petitions details" do
      petition = FactoryBot.create :open_petition

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "links" => a_hash_including(
              "self" => "https://petitions.senedd.wales/petitions/#{petition.id}.json"
            )
          )
        )
      )
    end

    it "includes the creator_name field for open petitions" do
      petition = FactoryBot.create :open_petition, creator_name: "Bob Jones"

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including("attributes" => a_hash_including("creator_name" => "Bob Jones"))
        )
      )
    end

    (Petition::VISIBLE_STATES - Array(Petition::OPEN_STATE)).each do |state_name|
      it "does not include the creator_name field for #{state_name} petitions" do
        petition = FactoryBot.create "#{state_name}_petition".to_sym

      get "/petitions.json"
      expect(response).to be_successful

        expect(data).not_to match(
          a_collection_containing_exactly(
            a_hash_including("attributes" => a_hash_including("creator_name" => "Bob Jones"))
          )
        )
      end
    end

    it "doesn't include the rejection section for non-rejected petitions" do
      petition = FactoryBot.create :open_petition

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "attributes" => a_hash_including(
              "rejected_at" => nil,
              "rejection" => nil
            )
          )
        )
      )
    end

    it "includes the rejection section for rejected petitions" do
      petition = \
        FactoryBot.create :rejected_petition,
          rejection_code: "duplicate",
          rejection_details: "This is a duplication of another petition"

      get "/petitions.json"
      expect(response).to be_successful

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

    it "includes the debate section for petitions that have been debated" do
      petition = \
        FactoryBot.create :debated_petition,
          debated_on: 1.day.ago,
          overview: "What happened in the debate",
          transcript_url: "https://record.assembly.wales/Plenary/5667#A51756",
          video_url: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
          debate_pack_url: "http://www.senedd.assembly.wales/ieListDocuments.aspx?CId=401&MId=5667"

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "attributes" => a_hash_including(
              "debate" => a_hash_including(
                "debated_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
                "overview" => "What happened in the debate",
                "transcript_url" => "https://record.assembly.wales/Plenary/5667#A51756",
                "video_url" => "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
                "debate_pack_url" => "http://www.senedd.assembly.wales/ieListDocuments.aspx?CId=401&MId=5667"
              )
            )
          )
        )
      )
    end
  end
end

