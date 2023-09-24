require 'rails_helper'

RSpec.describe FetchMembersJob, type: :job do
  let(:url) { "https://business.senedd.wales" }
  let(:members_en) { "#{url}/mgwebservice.asmx/GetCouncillorsByWard" }
  let(:members_cy) { "#{url}/mgwebservicew.asmx/GetCouncillorsByWard" }
  let(:stub_members_en_api) { stub_request(:get, members_en) }
  let(:stub_members_cy_api) { stub_request(:get, members_cy) }

  def xml_response(status, body = nil, &block)
    status = Rack::Utils.status_code(status)
    headers = { "Content-Type" => "text/xml; charset=utf-8" }

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
    FactoryBot.create(:constituency, :cardiff_south_and_penarth)
  end

  context "when the request is successful" do
    before do
      stub_members_en_api.to_return(xml_response(:ok, "members_en"))
      stub_members_cy_api.to_return(xml_response(:ok, "members_cy"))
    end

    it "imports members" do
      expect {
        described_class.perform_now
      }.to change {
        Member.count
      }.from(0).to(5)
    end

    describe "attribute assignment" do
      let(:member) { Member.find(249) }
      let(:members) { Member.pluck(:name_en) }

      before do
        described_class.perform_now
      end

      it "imports members" do
        expect(members).to include("Vaughan Gething MS")
        expect(members).to include("Andrew RT Davies MS")
        expect(members).to include("David Melding MS")
        expect(members).to include("Gareth Bennett MS")
        expect(members).to include("Neil McEvoy MS")
      end

      it "assigns the member id" do
        expect(member.id).to eq(249)
      end

      it "assigns the English member name" do
        expect(member.name_en).to eq("Vaughan Gething MS")
      end

      it "assigns the Welsh member name" do
        expect(member.name_cy).to eq("Vaughan Gething AS")
      end

      it "assigns the English party name" do
        expect(member.party_en).to eq("Welsh Labour")
      end

      it "assigns the Welsh party name" do
        expect(member.party_cy).to eq("Llafur Cymru")
      end
    end

    describe "association assignment" do
      context "for a constituency member" do
        let(:member) { Member.find(249) }

        before do
          described_class.perform_now
        end

        it "assigns the correct constituency" do
          expect(member.constituency_name).to eq("Cardiff South and Penarth")
        end
      end

      context "for a regional member" do
        let(:member) { Member.find(169) }

        before do
          described_class.perform_now
        end

        it "assigns the correct region" do
          expect(member.region_name).to eq("South Wales Central")
        end
      end
    end

    describe "error handling" do
      context "when a record fails to save" do
        let!(:member) { FactoryBot.create(:member, :cardiff_south_and_penarth) }
        let(:exception) { ActiveRecord::RecordInvalid.new(member) }

        it "notifies Appsignal of the failure" do
          expect(Member).to receive(:find_or_initialize_by).with(id: 249).and_return(member)
          expect(member).to receive(:save!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)

          described_class.perform_now
        end
      end
    end

    describe "updating members" do
      context "when a member is still in office" do
        let!(:member) { FactoryBot.create(:member, :cardiff_south_and_penarth, name: "Vaughan Gething AM") }

        it "updates the record" do
          expect {
            described_class.perform_now
          }.to change {
            member.reload.name
          }.from("Vaughan Gething AM").to("Vaughan Gething MS")
        end
      end

      context "when a constituency member is no longer in office" do
        let!(:member) { FactoryBot.create(:member, :constituency_member) }

        it "clears the constituency association" do
          expect {
            described_class.perform_now
          }.to change {
            member.reload.constituency_id
          }.from("W09000043").to(nil)
        end
      end

      context "when a regional member is no longer in office" do
        let!(:member) { FactoryBot.create(:member, :regional_member) }

        it "clears the region association" do
          expect {
            described_class.perform_now
          }.to change {
            member.reload.region_id
          }.from("W10000007").to(nil)
        end
      end
    end
  end

  context "when the request is unsuccessful" do
    context "because the API is not responding" do
      before do
        stub_members_en_api.to_timeout
        stub_members_cy_api.to_timeout
      end

      it "doesn't reset the members" do
        expect(Member).not_to receive(:update_all).with(region_id: nil, constituency_id: nil)
        described_class.perform_now
      end
    end

    context "because the API connection is blocked" do
      before do
        stub_members_en_api.to_return(xml_response(:proxy_authentication_required))
        stub_members_cy_api.to_return(xml_response(:proxy_authentication_required))
      end

      it "doesn't reset the members" do
        expect(Member).not_to receive(:update_all).with(region_id: nil, constituency_id: nil)
        described_class.perform_now
      end
    end

    context "because the API can't be found" do
      before do
        stub_members_en_api.to_return(xml_response(:not_found))
        stub_members_cy_api.to_return(xml_response(:not_found))
      end

      it "doesn't reset the members" do
        expect(Member).not_to receive(:update_all).with(region_id: nil, constituency_id: nil)
        described_class.perform_now
      end
    end

    context "because the API can't find the resource" do
      before do
        stub_members_en_api.to_return(xml_response(:not_acceptable))
        stub_members_cy_api.to_return(xml_response(:not_acceptable))
      end

      it "doesn't reset the members" do
        expect(Member).not_to receive(:update_all).with(region_id: nil, constituency_id: nil)
        described_class.perform_now
      end
    end

    context "because the API is returning an internal server error" do
      before do
        stub_members_en_api.to_return(xml_response(:internal_server_error))
        stub_members_cy_api.to_return(xml_response(:internal_server_error))
      end

      it "doesn't reset the members" do
        expect(Member).not_to receive(:update_all).with(region_id: nil, constituency_id: nil)
        described_class.perform_now
      end
    end
  end
end
