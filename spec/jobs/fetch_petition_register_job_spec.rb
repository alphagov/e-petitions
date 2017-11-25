require 'rails_helper'

RSpec.describe FetchCountryRegisterJob, type: :job do
  def stub_register
    stub_request(:get, "https://country.register.gov.uk/records.json?page-size=500")
  end

  def json_response(body = "{}")
    {status: 200, headers: {"Content-Type" => "application/json"}, body: body}
  end

  def json_error(status = 404, body = "{}")
    {status: status, headers: {"Content-Type" => "application/json"}, body: body}
  end

  context "when a country does not exist" do
    before do
      stub_register.to_return json_response <<-JSON
      {
          "GB" : {
            "index-entry-number": "6",
            "entry-number": "6",
            "entry-timestamp": "2016-04-05T13:23:05Z",
            "key": "GB",
            "item": [{
              "citizen-names": "Briton;British citizen",
              "country": "GB",
              "name": "United Kingdom",
              "official-name": "The United Kingdom of Great Britain and Northern Ireland",
              "start-date": "1707-05-01",
              "end-date": "2017-12-31"
            }]
          }
      }
      JSON
    end

    it "creates a record" do
      expect {
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change { Location.count }.by(1)
    end

    describe "attribute assignment" do
      let(:location) { Location.find_by!(code: "GB") }

      before do
        perform_enqueued_jobs {
          described_class.perform_later
        }
      end

      it "assigns 'country' to Location#code" do
        expect(location.code).to eq("GB")
      end

      it "assigns 'name' to Location#name" do
        expect(location.name).to eq("United Kingdom")
      end

      it "assigns 'start-date' to Location#start_date" do
        expect(location.start_date).to eq(Date.civil(1707, 5, 1))
      end

      it "assigns 'end-date' to Location#end_date" do
        expect(location.end_date).to eq(Date.civil(2017, 12, 31))
      end
    end
  end

  context "when a country does exist" do
    before do
      FactoryBot.create(:location, code: "GB")

      stub_register.to_return json_response <<-JSON
      {
          "GB" : {
            "index-entry-number": "6",
            "entry-number": "6",
            "entry-timestamp": "2016-04-05T13:23:05Z",
            "key": "GB",
            "item": [{
              "citizen-names": "Briton;British citizen",
              "country": "GB",
              "name": "United Kingdom",
              "official-name": "The United Kingdom of Great Britain and Northern Ireland",
              "start-date": "1707-05-01",
              "end-date": "2017-12-31"
            }]
          }
      }
      JSON
    end

    it "updates an existing record" do
      expect {
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.not_to change { Location.count }
    end

    describe "attribute assignment" do
      let(:location) { Location.find_by!(code: "GB") }

      before do
        perform_enqueued_jobs {
          described_class.perform_later
        }
      end

      it "updates Location#name" do
        expect(location.name).to eq("United Kingdom")
      end

      it "updates Location#start_date" do
        expect(location.start_date).to eq(Date.civil(1707, 5, 1))
      end

      it "updates Location#end_date" do
        expect(location.end_date).to eq(Date.civil(2017, 12, 31))
      end
    end
  end

  context "when a country does not change" do
    let(:location) { Location.find_by!(code: "GB") }

    before do
      FactoryBot.create(:location, code: "GB", name: "United Kingdom")

      stub_register.to_return json_response <<-JSON
      {
          "GB" : {
            "index-entry-number": "6",
            "entry-number": "6",
            "entry-timestamp": "2016-04-05T13:23:05Z",
            "key": "GB",
            "item": [{
              "citizen-names": "Briton;British citizen",
              "country": "GB",
              "name": "United Kingdom",
              "official-name": "The United Kingdom of Great Britain and Northern Ireland"
            }]
          }
      }
      JSON
    end

    it "doesn't update an existing record" do
      expect {
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.not_to change { location.reload.updated_at }
    end
  end

  context "when the API returns an error" do
    before do
      stub_register.to_return json_error
    end

    it "captures the error" do
      perform_enqueued_jobs {
        described_class.perform_later
      }

      expect(enqueued_jobs.size).to eq(0)
    end

    it "notifies Appsignal" do
      expect(Appsignal).to receive(:send_exception).with(an_instance_of(Faraday::ResourceNotFound))

      perform_enqueued_jobs {
        described_class.perform_later
      }
    end
  end
end
