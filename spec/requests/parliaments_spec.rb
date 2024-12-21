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
    before do
      FactoryBot.create(
        :parliament, :dissolved,
        state_opening_at: "2021/05/23",
        opening_at: "2021/05/30",
        dissolution_at: "2022/06/30",
        archived_at: "2022/08/30"
      )

      FactoryBot.create(
        :parliament, :dissolved,
        state_opening_at: "2022/05/23",
        opening_at: "2022/05/30",
        dissolution_at: "2023/06/30",
        archived_at: "2023/08/30"
      )
    end

    subject(:json) { JSON.parse(response.body) }

    it "returns a list of parliaments" do
      get "/parliaments.json"

      expect(json).to match([
        {
          "period"             => "2022-2023",
          "dissolution_at"     => "2023-06-30T00:00:00.000+01:00",
          "government"         => "Conservative",
          "response_threshold" => 10000,
          "debate_threshold"   => 100000
        },
        {
          "period"             => "2021-2022",
          "dissolution_at"     => "2022-06-30T00:00:00.000+01:00",
          "government"         => "Conservative",
          "response_threshold" => 10000,
          "debate_threshold"   => 100000
        }
      ])
    end
  end

  describe "data fields for constituencies" do
    before do
      parliament = FactoryBot.build(
        :parliament, :dissolved,
        state_opening_at: "2021/05/23",
        opening_at: "2021/05/30",
        dissolution_at: "2022/06/30",
        archived_at: "2022/08/30"
      )

      parliament.constituencies << FactoryBot.build(:constituency, name: "Altrincham and Sale West", ons_code: "E14000532")
      parliament.constituencies << FactoryBot.build(:constituency, name: "Aldershot", ons_code: "E14000530")
      parliament.constituencies << FactoryBot.build(:constituency, name: "Aldridge-Brownhills", ons_code: "E14000531")

      parliament.save!
    end

    subject(:json) { JSON.parse(response.body) }

    it "returns a list of constituencies for a specific parliament" do
      get "/parliaments/2021-2022.json"

      expect(json).to match({
        "period"             => "2021-2022",
        "dissolution_at"     => "2022-06-30T00:00:00.000+01:00",
        "government"         => "Conservative",
        "response_threshold" => 10000,
        "debate_threshold"   => 100000,
        "constituencies"     => {
          "E14000530" => {
            "constituency" =>"Aldershot",
            "ons_code"     => "E14000530",
            "start_date"   => "2010-04-13",
            "end_date"     => nil
          },
          "E14000531" => {
            "constituency" => "Aldridge-Brownhills",
            "ons_code"     => "E14000531",
            "start_date"   => "2010-04-13",
            "end_date"     => nil
          },
          "E14000532" => {
            "constituency" => "Altrincham and Sale West",
            "ons_code"     => "E14000532",
            "start_date"   => "2010-04-13",
            "end_date"     => nil
          }
        }
      })
    end
  end
end
