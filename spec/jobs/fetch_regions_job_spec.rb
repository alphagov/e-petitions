require 'rails_helper'

RSpec.describe FetchRegionsJob, type: :job do
  let(:url) { "http://data.parliament.uk/membersdataplatform/open/OData.svc" }
  let(:regions_api) { "#{url}/Areas?$filter=AreaType_Id%20eq%208&$orderby=OnsAreaId&$select=Area_Id,Name,OnsAreaId"}
  let(:stub_regions_api) { stub_request(:get, regions_api) }

  def odata_response(status, body = nil, &block)
    status = Rack::Utils.status_code(status)
    headers = { "Content-Type" => "application/atom+xml;type=feed;charset=utf-8" }

    if block_given?
      body = block.call
    elsif body
      body = file_fixture("#{body}.xml").read
    else
      body = <<~XML
        <?xml version="1.0" encoding="utf-8" standalone="yes"?>
        <error xmlns="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata">
          <code>#{status}</code>
          <message xml:lang="en-US">Error Message</message>
        </error>
      XML
    end

    { status: status, headers: headers, body: body }
  end

  before do
    Region.delete_all
  end

  context "when the request is successful" do
    it "imports regions" do
      stub_regions_api.to_return(odata_response(:ok, "regions"))

      expect { described_class.perform_now }.to change { Region.count }
    end

    describe "attribute assignment" do
      let(:region) { Region.first }
      let(:regions) { Region.pluck(:name) }

      before do
        stub_regions_api.to_return(odata_response(:ok, "regions"))

        described_class.perform_now
      end

      it "imports regions" do
        expect(regions).to include("Yorkshire and The Humber")
        expect(regions).to include("West Midlands")
        expect(regions).to include("London")
      end

      it "assigns the region id" do
        expect(region.external_id).to eq("109")
      end

      it "assigns the region name" do
        expect(region.name).to eq("Yorkshire and The Humber")
      end

      it "assigns the region ONS code" do
        expect(region.ons_code).to eq("D")
      end
    end

    describe "error handling" do
      before do
        stub_regions_api.to_return(odata_response(:ok, "regions"))
      end

      context "when a record fails to save" do
        let!(:region) { FactoryBot.create(:region, :yorkshire_and_the_humber) }
        let(:exception) { ActiveRecord::RecordInvalid.new(region) }

        it "notifies Appsignal of the failure" do
          expect(Region).to receive(:find_or_initialize_by).with(external_id: "109").and_return(region)
          expect(region).to receive(:save!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)

          described_class.perform_now
        end
      end
    end
  end

  context "when the request is unsuccessful" do
    context "because the API is not responding" do
      before do
        stub_regions_api.to_timeout
      end

      it "doesn't import any regions" do
        expect { described_class.perform_now }.not_to change { Region.count }
      end
    end

    context "because the API connection is blocked" do
      before do
        stub_regions_api.to_return(odata_response(:proxy_authentication_required))
      end

      it "doesn't import any regions" do
        expect { described_class.perform_now }.not_to change { Region.count }
      end
    end

    context "because the API can't be found" do
      before do
        stub_regions_api.to_return(odata_response(:not_found))
      end

      it "doesn't import any regions" do
        expect { described_class.perform_now }.not_to change { Region.count }
      end
    end

    context "because the API can't find the resource" do
      before do
        stub_regions_api.to_return(odata_response(:not_acceptable))
      end

      it "doesn't import any regions" do
        expect { described_class.perform_now }.not_to change { Region.count }
      end
    end

    context "because the API is returning an internal server error" do
      before do
        stub_regions_api.to_return(odata_response(:internal_server_error))
      end

      it "doesn't import any regions" do
        expect { described_class.perform_now }.not_to change { Region.count }
      end
    end
  end
end
