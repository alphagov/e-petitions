require 'rails_helper'

RSpec.describe "API request to display parliaments", type: :request, show_exceptions: true do
  let(:parliament) { FactoryBot.create :parliament}
  let(:attributes) { json["data"]["attributes"] }
  
  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  describe "format" do
    it "responds to JSON" do
      get "/parliaments.json"
      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get "/parliaments.json"

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to HTML" do
      get "/parliaments"
      expect(response.status).to eq(406)
    end

    it "does not respond to XML" do
      get "/parliaments.xml"
      expect(response.status).to eq(406)
    end
  end

  describe "data fields" do
    it "returns a list of parliaments", :skip_before_hook do
      parliament = FactoryBot.create(:parliament, :dissolved)
      parliament_2 = FactoryBot.create(:parliament, opening_at: "2023/05/30", period: "2023-2024")

      get "/parliaments.json"

      expect(JSON.parse(response.body)[JSON.parse(response.body).keys.first]).to match({"archived_at"=>nil, "debate_threshold"=>100000, "dissolution_at"=>nil, "election_date"=>nil, "government"=>"Conservative", "opening_at"=>"2023-05-30T00:00:00.000+01:00", "period"=>"2023-2024", "response_threshold"=>10000})
    end
  end

  describe "data fields for constituencies", :skip_before_hook do
    it "returns a list of constituencies for a specific parliament" do
      parliament = FactoryBot.create(:parliament, opening_at: "2023/05/30", period: "2023-2024")
      constituency = FactoryBot.create(:constituency, name: "Buckinghamshire", mp_name: "Naoma Green", ons_code: "E00000001", party: "Test Party")
      constituency_2 = FactoryBot.create(:constituency)

      parliament.constituencies << constituency
      parliament.constituencies << constituency_2

      get "/parliaments/2023-2024.json"
      
      expect(JSON.parse(response.body)["period"]).to match("2023-2024")
      expect(JSON.parse(response.body)["constituencies"].length).to match(2)
      expect(JSON.parse(response.body)["constituencies"].first).to match({"constituency"=>"Buckinghamshire", "end_date"=>nil, "mp"=>"Naoma Green", "ons_code"=>"E00000001", "party"=>"Test Party", "start_date"=>nil})
    end
  end
end
