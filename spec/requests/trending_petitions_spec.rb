require 'rails_helper'

RSpec.describe "API request to trending petitions", type: :request, show_exceptions: true do
  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  describe "format" do
    it "responds to JSON" do
      get "/trending.json"
      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get "/trending.json"

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to HTML" do
      get "/trending"
      expect(response.status).to eq(404)
    end

    it "does not respond to XML" do
      get "/trending.xml"
      expect(response.status).to eq(404)
    end
  end

  describe "links" do
    let(:links) { json["links"] }

    it "returns a link to itself" do
      get "/trending.json"

      expect(response).to be_successful
      expect(links).to include("self" => "https://petition.parliament.uk/trending.json")
    end
  end

  describe "data" do
    let(:data) { json["data"] }

    it "returns an empty response if no petitions are trending" do
      get "/trending.json"

      expect(response).to be_successful
      expect(data).to be_empty
    end

    it "returns a list of serialized petitions in the expected order" do
      relation = double(ActiveRecord::Relation)
      expect(Petition).to receive(:trending).and_return(relation)
      expect(relation).to receive(:pluck).and_return(
        [
          [100123, "Do something!", 128],
          [100321, "Don’t do anything!", 64],
          [100213, "Free the wombles!", 32],
          [100231, "Leave the wombles locked up!", 16]
        ]
      )

      get "/trending.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          {
            "type" => "petition", "id" => 100123, "links" => {
              "self" => "https://petition.parliament.uk/petitions/100123.json"
            }, "attributes" => {
              "action" => "Do something!", "signature_count" => 128
            }
          },
          {
            "type" => "petition", "id" => 100321, "links" => {
              "self" => "https://petition.parliament.uk/petitions/100321.json"
            }, "attributes" => {
              "action" => "Don’t do anything!", "signature_count" => 64
            }
          },
          {
            "type" => "petition", "id" => 100213, "links" => {
              "self" => "https://petition.parliament.uk/petitions/100213.json"
            }, "attributes" => {
              "action" => "Free the wombles!", "signature_count" => 32
            }
          },
          {
            "type" => "petition", "id" => 100231, "links" => {
              "self" => "https://petition.parliament.uk/petitions/100231.json"
            }, "attributes" => {
              "action" => "Leave the wombles locked up!", "signature_count" => 16
            }
          }
        )
      )
    end
  end

  describe "meta" do
    let(:meta) { json["meta"] }
    let(:time) { Time.at(1616240245).in_time_zone }

    around do |example|
      travel_to(time) { example.run }
    end

    it "returns the quantized timestamp" do
      get "/trending.json"

      expect(response).to be_successful
      expect(meta).to include("updated_at" => "2021-03-20T11:37:00.000Z")
    end
  end
end
