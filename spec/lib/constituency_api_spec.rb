require 'rails_helper'

RSpec.describe ConstituencyApi do
  describe ConstituencyApi::Mp do
    describe "#initialize" do
      let(:mp) { ConstituencyApi::Mp.new("1536", "Emily Thornberry MP", "2015-05-07T00:00:00") }

      it "converts valid date string into a datetime variable" do
        expect(mp.start_date).to eq Date.new(2015, 5, 7)
      end
    end

    describe "#url" do
      let(:mp) { ConstituencyApi::Mp.new("1536", "Emily Thornberry MP", Date.new(2015, 5, 7)) }

      it "returns the URL for the mp" do
        expect(mp.url).to eq "#{ConstituencyApi::Mp::URL}/emily-thornberry-mp/1536"
      end
    end
  end

  describe "query methods" do
    let(:api) { ConstituencyApi::Client }
    let(:url) { "http://data.parliament.uk" }
    let(:endpoint) { "#{url}/membersdataplatform/services/mnis/Constituencies" }

    def stub_api_request(postcode, status, body)
      stub_request(:get, api_url(postcode)).to_return(api_response(status, body))
    end

    def api_url(postcode)
      "#{endpoint}/#{postcode}/"
    end

    def api_response(status, body)
      { status: status, body: api_fixture(body) }
    end

    def api_fixture(body)
      File.read(Rails.root.join("spec", "fixtures", "constituency_api", "#{body}.xml"))
    end

    def mp(id, name)
      ConstituencyApi::Mp.new(id, name, Date.new(2015, 5, 7))
    end

    def constituency(id, name, mp = nil, &block)
      ConstituencyApi::Constituency.new(id, name, (block_given? ? block.call : mp))
    end

    describe "#constituency" do
      context "when there multiple constituencies" do
        before do
          stub_api_request("N1", 200, "multiple")
        end

        it "returns the first constituency result" do
          expect(api.constituency("N1")).to eq(
            constituency("3506", "Hackney North and Stoke Newington") {
              mp("172", "Ms Diane Abbott MP")
            }
          )
        end
      end
    end

    describe "#constituencies" do
      context "when an invalid postcode is supplied" do
        before do
          stub_api_request("SW149RQ", 200, "no_results")
        end

        it "returns an empty array" do
          expect(api.constituencies("SW14 9RQ")).to eq([])
        end
      end

      context "when there is a single result" do
        before do
          stub_api_request("N11TY", 200, "single")
        end

        it "returns an array" do
          expect(api.constituencies("N11TY")).to eq([
            constituency("3550", "Islington South and Finsbury") {
              mp("1536", "Emily Thornberry MP")
            }
          ])
        end

        it "returns an array for a postcode with whitespaces" do
          expect(api.constituencies("N1 1TY ")).to eq([
            constituency("3550", "Islington South and Finsbury") {
              mp("1536", "Emily Thornberry MP")
            }
          ])
        end

        it "returns an array for a postcode with lowercase characters" do
          expect(api.constituencies("n11ty")).to eq([
            constituency("3550", "Islington South and Finsbury") {
              mp("1536", "Emily Thornberry MP")
            }
          ])
        end
      end

      context "when there are multiple constituencies" do
        before do
          stub_api_request("N1", 200, "multiple")
        end

        it "returns an array with multiple entries" do
          expect(api.constituencies("N1")).to eq([
            constituency("3506", "Hackney North and Stoke Newington") {
              mp("172", "Ms Diane Abbott MP")
            },
            constituency("3507", "Hackney South and Shoreditch") {
              mp("1524", "Meg Hillier MP")
            },
            constituency("3536", "Holborn and St Pancras") {
              mp("4514", "Keir Starmer MP")
            },
            constituency("3549", "Islington North") {
              mp("185", "Jeremy Corbyn MP")
            },
            constituency("3550", "Islington South and Finsbury") {
              mp("1536", "Emily Thornberry MP")
            }
          ])
        end
      end

      context "when the MP has changed" do
        before do
          stub_api_request("N1C4QP", 200, "changed")
        end

        it "returns an array with the last MP" do
          expect(api.constituencies("N1C 4QP")).to eq([
            constituency("3536", "Holborn and St Pancras") {
              mp("4514", "Keir Starmer MP")
            }
          ])
        end
      end

      context "when there is no sitting MP" do
        before do
          stub_api_request("N11TY", 200, "no_mps")
        end

        it "handles a constituency without an MP" do
          expect(api.constituencies("N1 1TY")).to eq([
            constituency("3550", "Islington South and Finsbury", nil)
          ])
        end
      end

      context "when the API is not responding" do
        before do
          stub_request(:get, /.*data.parliament.uk.*/).to_timeout
        end

        it "raises a ConstituencyApi::Error" do
          expect{ api.constituencies("N1") }.to raise_error(ConstituencyApi::Error)
        end
      end

      context "when the API is blocking connections" do
        before do
          stub_request(:get, /.*data.parliament.uk.*/).to_raise(Faraday::Error::ConnectionFailed)
        end

        it "raises a ConstituencyApi::Error" do
          expect{ api.constituencies("N1") }.to raise_error(ConstituencyApi::Error)
        end
      end

      context "when the API can't find the resource" do
        before do
          stub_request(:get, /.*data.parliament.uk.*/).to_raise(Faraday::Error::ResourceNotFound)
        end

        it "raises a ConstituencyApi::Error" do
          expect{ api.constituencies("N1") }.to raise_error(ConstituencyApi::Error)
        end
      end

      context "when the API is returning an internal server error" do
        before do
          stub_request(:get, /.*data.parliament.uk.*/).to_return(status: 500, body: "<Constituencies/>")
        end

        it "raises a ConstituencyApi::Error" do
          expect{ api.constituencies("N1") }.to raise_error(ConstituencyApi::Error)
        end
      end
    end
  end
end
