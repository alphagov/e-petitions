require 'rails_helper'

RSpec.describe RefreshConstituencyPartyJob, type: :job do
  def stub_members_api
    stub_request(:get, "http://data.parliament.uk/membersdataplatform/services/mnis/members/query/House=Commons%7CIsEligible=true/")
  end

  def xml_response(body = "<Members />")
    {status: 200, headers: {"Content-Type" => "application/xml"}, body: body}
  end

  def xml_error(status = 404, body = "<Members />")
    {status: status, headers: {"Content-Type" => "application/xml"}, body: body}
  end

  let!(:constituency) { FactoryBot.create(:constituency, :coventry_north_east) }

  context "when the API returns a 200 OK response" do
    before do
      expect(Constituency).to receive(:find_each).and_yield(constituency)
    end

    context "and the MP is active" do
      before do
        stub_members_api.to_return xml_response <<-XML
          <Members>
            <Member Member_Id="4378" Dods_Id="109467" Pims_Id="6062">
              <DisplayAs>Colleen Fletcher</DisplayAs>
              <ListAs>Fletcher, Colleen</ListAs>
              <FullTitle>Colleen Fletcher MP</FullTitle>
              <LayingMinisterName/>
              <DateOfBirth>1954-11-23T00:00:00</DateOfBirth>
              <DateOfDeath xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
              <Gender>F</Gender>
              <Party Id="15">Labour</Party>
              <House>Commons</House>
              <MemberFrom>Coventry North East</MemberFrom>
              <HouseStartDate>2015-05-07T00:00:00</HouseStartDate>
              <HouseEndDate xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
              <CurrentStatus Id="0" IsActive="True">
                <Name>Current Member</Name>
                <Reason/>
                <StartDate>2017-06-08T00:00:00</StartDate>
              </CurrentStatus>
            </Member>
          </Members>
        XML
      end

      it "updates the constituency with the party" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later
          }
        }.to change {
          constituency.reload.party
        }.from(nil).to("Labour")
      end
    end

    context "and the MP is not active" do
      before do
        stub_members_api.to_return xml_response <<-XML
          <Members />
        XML
      end

      it "clears the constituency mp id" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later
          }
        }.to change {
          constituency.reload.mp_id
        }.from("4378").to(nil)
      end

      it "clears the constituency mp name" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later
          }
        }.to change {
          constituency.reload.mp_name
        }.from("Colleen Fletcher MP").to(nil)
      end

      it "clears the constituency mp date" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later
          }
        }.to change {
          constituency.reload.mp_date
        }.from(Date.civil(2015, 5, 7)).to(nil)
      end
    end
  end

  context "when the API returns a HTTP error" do
    before do
      stub_members_api.to_return(xml_error)
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

  context "when the API times out" do
    before do
      stub_members_api.to_timeout
    end

    it "captures the error" do
      perform_enqueued_jobs {
        described_class.perform_later
      }

      expect(enqueued_jobs.size).to eq(0)
    end

    it "notifies Appsignal" do
      expect(Appsignal).to receive(:send_exception).with(an_instance_of(Faraday::TimeoutError))

      perform_enqueued_jobs {
        described_class.perform_later
      }
    end
  end
end
