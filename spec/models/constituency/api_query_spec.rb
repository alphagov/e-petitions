require 'rails_helper'

RSpec.describe Constituency::ApiQuery, type: :model do
  let(:query) { described_class.new }

  def constituency(external_id, name, ons_code, mp_id = nil, mp_name = nil, mp_date = nil)
    if mp_id
      mp_date = mp_date ? mp_date : "2015-05-07T00:00:00+01:00"
    end

    FactoryGirl.attributes_for(:constituency, {
      name: name, external_id: external_id, ons_code: ons_code,
      mp_id: mp_id, mp_name: mp_name, mp_date: mp_date
    })
  end

  describe "#fetch" do
    context "when the request is successful" do
      context "and an invalid postcode is supplied" do
        before do
          stub_api_request_for("SW149RQ").to_return(api_response(:ok, "no_results"))
        end

        it "returns an empty array" do
          expect(query.fetch("SW149RQ")).to eq([])
        end
      end

      context "and there is a single result" do
        before do
          stub_api_request_for("N11TY").to_return(api_response(:ok, "single"))
        end

        it "returns an array" do
          expect(query.fetch("N11TY")).to eq([{
            name: "Islington South and Finsbury", external_id: "3550", ons_code: "E14000764",
            mp_id: "1536", mp_name: "Emily Thornberry MP", mp_date: "2015-05-07T00:00:00"
          }])
        end
      end

      context "and there are multiple constituencies" do
        before do
          stub_api_request_for("N1").to_return(api_response(:ok, "multiple"))
        end

        it "returns an array with multiple entries" do
          expect(query.fetch("N1")).to match([{
            name: "Hackney North and Stoke Newington", external_id: "3506", ons_code: "E14000720",
            mp_id: "172", mp_name: "Ms Diane Abbott MP", mp_date: "2015-05-07T00:00:00"
          },{
            name: "Hackney South and Shoreditch", external_id: "3507", ons_code: "E14000721",
            mp_id: "1524", mp_name: "Meg Hillier MP", mp_date: "2015-05-07T00:00:00"
          },{
            name: "Holborn and St Pancras", external_id: "3536", ons_code: "E14000750",
            mp_id: "4514", mp_name: "Keir Starmer MP", mp_date: "2015-05-07T00:00:00"
          },{
            name: "Islington North", external_id: "3549", ons_code: "E14000763",
            mp_id: "185", mp_name: "Jeremy Corbyn MP", mp_date: "2015-05-07T00:00:00"
          },{
            name: "Islington South and Finsbury", external_id: "3550", ons_code: "E14000764",
            mp_id: "1536", mp_name: "Emily Thornberry MP", mp_date: "2015-05-07T00:00:00"
          }])
        end
      end

      context "when the MP has changed" do
        before do
          stub_api_request_for("N1C4QP").to_return(api_response(:ok, "changed"))
        end

        it "returns an array with the last MP" do
          expect(query.fetch("N1C4QP")).to eq([{
            name: "Holborn and St Pancras", external_id: "3536", ons_code: "E14000750",
            mp_id: "4514", mp_name: "Keir Starmer MP", mp_date: "2015-05-07T00:00:00"
          }])
        end
      end

      context "when there is no sitting MP" do
        before do
          stub_api_request_for("N11TY").to_return(api_response(:ok, "no_mps"))
        end

        it "handles a constituency without an MP" do
          expect(query.fetch("N11TY")).to eq([{
            name: "Islington South and Finsbury", external_id: "3550", ons_code: "E14000764"
          }])
        end
      end

      context "when the current MP has passed away" do
        before do
          stub_api_request_for("S48AA").to_return(api_response(:ok, "vacant"))
        end

        it "sets the MP details to nil" do
          expect(query.fetch("S48AA")).to eq([{
            name: "Sheffield, Brightside and Hillsborough", external_id: "3724",
            ons_code: "E14000921", mp_id: nil, mp_name: nil, mp_date: nil
          }])
        end
      end
    end

    context "when the request is unsuccessful" do
      context "when the API is not responding" do
        before do
          stub_api_request_for("N1").to_timeout
        end

        it "returns an empty array" do
          expect(query.fetch("N1")).to eq([])
        end
      end

      context "when the API connection is blocked" do
        before do
          stub_api_request_for("N1").to_return(api_response(:proxy_authentication_required))
        end

        it "returns an empty array" do
          expect(query.fetch("N1")).to eq([])
        end
      end

      context "when the API can't be found" do
        before do
          stub_api_request_for("N1").to_return(api_response(:not_found))
        end

        it "returns an empty array" do
          expect(query.fetch("N1")).to eq([])
        end
      end

      context "when the API can't find the resource" do
        before do
          stub_api_request_for("N1").to_return(api_response(:not_acceptable))
        end

        it "returns an empty array" do
          expect(query.fetch("N1")).to eq([])
        end
      end

      context "when the API is returning an internal server error" do
        before do
          stub_api_request_for("N1").to_return(api_response(:internal_server_error))
        end

        it "returns an empty array" do
          expect(query.fetch("N1")).to eq([])
        end
      end
    end
  end
end
