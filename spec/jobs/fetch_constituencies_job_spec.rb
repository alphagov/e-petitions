require 'rails_helper'

RSpec.describe FetchConstituenciesJob, type: :job do
  let(:url) { "http://data.parliament.uk/membersdataplatform/open/OData.svc" }
  let(:constituency_api) { "#{url}/Constituencies?$filter=(EndDate%20gt%20datetime'2015-05-07')%20or%20(EndDate%20eq%20null)&$orderby=ONSCode&$select=Constituency_Id,Name,ONSCode,StartDate,EndDate" }
  let(:stub_constituency_api) { stub_request(:get, constituency_api) }
  let(:member_api) { "#{url}/Members?$filter=(CurrentStatusActive%20eq%20true)%20and%20(House_Id%20eq%201)&$orderby=Member_Id&$select=Member_Id,NameFullTitle,Party,MembershipFrom_Id,StartDate" }
  let(:stub_member_api) { stub_request(:get, member_api) }
  let(:regions_api) { "#{url}/ConstituencyAreas?$filter=(Area/AreaType_Id%20eq%208)%20and%20((Constituency/EndDate%20gt%20datetime'2015-05-07')%20or%20(Constituency/EndDate%20eq%20null))&$orderby=Area_Id,Constituency_Id&$select=Area_Id,Constituency_Id"}
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
    stub_regions_api.to_return(odata_response(:ok, "constituency_regions"))
  end

  context "when the request is successful" do
    it "imports constituencies" do
      stub_member_api.to_return(odata_response(:ok, "members"))
      stub_constituency_api.to_return(odata_response(:ok, "constituencies"))

      expect { described_class.perform_now }.to change { Constituency.count }
    end

    describe "attribute assignment" do
      let(:constituency) { Constituency.first }
      let(:constituencies) { Constituency.pluck(:name) }

      before do
        stub_member_api.to_return(odata_response(:ok, "members"))
        stub_constituency_api.to_return(odata_response(:ok, "constituencies"))

        described_class.perform_now
      end

      it "imports constituencies without an end date" do
        expect(constituencies).to include("Bethnal Green and Bow")
        expect(constituencies).to include("Coventry North East")
        expect(constituencies).to include("Sheffield, Brightside and Hillsborough")
      end

      it "assigns the constituency id" do
        expect(constituency.external_id).to eq("3320")
      end

      it "assigns the constituency name" do
        expect(constituency.name).to eq("Bethnal Green and Bow")
      end

      it "assigns the constituency ONS code" do
        expect(constituency.ons_code).to eq("E14000555")
      end

      it "assigns the constituency example postcode" do
        expect(constituency.example_postcode).to eq("E18FF")
      end
    end

    describe "updating constituencies" do
      let!(:constituency) { FactoryBot.create(:constituency, :bethnal_green_and_bow) }

      context "when parliament has dissolved" do
        before do
          stub_member_api.to_return(odata_response(:ok, "dissolved"))
          stub_constituency_api.to_return(odata_response(:ok, "constituencies"))
        end

        it "clears the constituency mp id" do
          expect {
            described_class.perform_now
          }.to change {
            constituency.reload.mp_id
          }.from("4138").to(nil)
        end

        it "clears the constituency mp name" do
          expect {
            described_class.perform_now
          }.to change {
            constituency.reload.mp_name
          }.from("Rushanara Ali MP").to(nil)
        end

        it "clears the constituency mp date" do
          expect {
            described_class.perform_now
          }.to change {
            constituency.reload.mp_date
          }.from(Date.civil(2010, 5, 6)).to(nil)
        end

        it "clears the constituency party" do
          expect {
            described_class.perform_now
          }.to change {
            constituency.reload.party
          }.from("Labour").to(nil)
        end
      end

      context "when there's been a general election" do
        before do
          stub_member_api.to_return(odata_response(:ok, "members"))
          stub_constituency_api.to_return(odata_response(:ok, "constituencies"))

          constituency.update_columns(mp_id: nil, mp_name: nil, mp_date: nil, party: nil)
        end

        it "sets the constituency mp id" do
          expect {
            described_class.perform_now
          }.to change {
            constituency.reload.mp_id
          }.from(nil).to("4138")
        end

        it "sets the constituency mp name" do
          expect {
            described_class.perform_now
          }.to change {
            constituency.reload.mp_name
          }.from(nil).to("Rushanara Ali MP")
        end

        it "sets the constituency mp date" do
          expect {
            described_class.perform_now
          }.to change {
            constituency.reload.mp_date
          }.from(nil).to(Date.civil(2010, 5, 6))
        end

        it "sets the constituency party" do
          expect {
            described_class.perform_now
          }.to change {
            constituency.reload.party
          }.from(nil).to("Labour")
        end
      end
    end

    describe "error handling" do
      before do
        stub_member_api.to_return(odata_response(:ok, "members"))
        stub_constituency_api.to_return(odata_response(:ok, "constituencies"))
      end

      context "when a record is duplicated" do
        let(:constituency) { instance_spy(Constituency) }

        before do
          allow(Constituency).to receive(:find_or_initialize_by).and_call_original
          allow(Constituency).to receive(:find_or_initialize_by).with(external_id: "3320").and_return(constituency)
          allow(constituency).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)
        end

        it "retries twice before skipping" do
          described_class.perform_now
          expect(constituency).to have_received(:save!).twice
        end
      end

      context "when a record fails to save" do
        let!(:constituency) { FactoryBot.create(:constituency, :bethnal_green_and_bow) }
        let(:exception) { ActiveRecord::RecordInvalid.new(constituency) }

        it "notifies Appsignal of the failure" do
          expect(Constituency).to receive(:find_or_initialize_by).with(external_id: "3320").and_return(constituency)
          expect(constituency).to receive(:save!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)

          described_class.perform_now
        end
      end
    end
  end

  context "when the request is unsuccessful" do
    context "because the API is not responding" do
      before do
        stub_constituency_api.to_timeout
      end

      it "doesn't import any constituencies" do
        expect { described_class.perform_now }.not_to change { Constituency.count }
      end
    end

    context "because the API connection is blocked" do
      before do
        stub_constituency_api.to_return(odata_response(:proxy_authentication_required))
      end

      it "doesn't import any constituencies" do
        expect { described_class.perform_now }.not_to change { Constituency.count }
      end
    end

    context "because the API can't be found" do
      before do
        stub_constituency_api.to_return(odata_response(:not_found))
      end

      it "doesn't import any constituencies" do
        expect { described_class.perform_now }.not_to change { Constituency.count }
      end
    end

    context "because the API can't find the resource" do
      before do
        stub_constituency_api.to_return(odata_response(:not_acceptable))
      end

      it "doesn't import any constituencies" do
        expect { described_class.perform_now }.not_to change { Constituency.count }
      end
    end

    context "because the API is returning an internal server error" do
      before do
        stub_constituency_api.to_return(odata_response(:internal_server_error))
      end

      it "doesn't import any constituencies" do
        expect { described_class.perform_now }.not_to change { Constituency.count }
      end
    end
  end
end
