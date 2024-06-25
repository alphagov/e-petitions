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
      parliament = FactoryBot.create(:parliament, :dissolved, opening_at: "2021/05/30", dissolution_at: "2022/06/30", period: "2021-2022", archived_at: "2022/08/30")
      parliament_2 = FactoryBot.create(:parliament, :dissolved, opening_at: "2022/05/30", dissolution_at: "2023/06/30", period: "2023-2024", archived_at: "2023/08/30")

      get "/parliaments.json"

      expect(JSON.parse(response.body).first).to match({"debate_threshold"=>100000, "dissolution_at"=>"2023-06-30T00:00:00.000+01:00", "government"=>"Conservative", "period"=>"2022-2023", "response_threshold"=>10000})
    end
  end

  describe "data fields for constituencies", :skip_before_hook do
    it "returns a list of constituencies for a specific parliament" do
      parliament = FactoryBot.create(:parliament, :dissolved, opening_at: "2021/05/30", dissolution_at: "2022/06/30", period: "2021-2022", archived_at: "2022/08/30")
      constituency = FactoryBot.create(:constituency, name: "Buckinghamshire", ons_code: "E00000001")
      constituency_2 = FactoryBot.create(:constituency, name: "Aberafan")

      parliament.constituencies << constituency
      parliament.constituencies << constituency_2

      get "/parliaments/2021-2022.json"
      
      expect(JSON.parse(response.body)["period"]).to match("2021-2022")
      expect(JSON.parse(response.body)["constituencies"].length).to match(2)
      expect(JSON.parse(response.body)["constituencies"].first).to match({"constituency"=>"Buckinghamshire", "end_date"=>nil, "ons_code"=>"E00000001", "start_date"=>nil})
    end
  end
end
