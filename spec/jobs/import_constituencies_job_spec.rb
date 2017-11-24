require 'rails_helper'

RSpec.describe ImportConstituenciesJob, type: :job do
  def stub_api
    stub_request(:get, "http://data.parliament.uk/membersdataplatform/services/mnis/ReferenceData/Constituencies/")
  end

  def reference_data_response(status, body = nil, &block)
    status = Rack::Utils.status_code(status)
    headers = { "Content-Type" => "application/json" }

    if block_given?
      body = block.call
    elsif body
      body = File.read(Rails.root.join("spec", "fixtures", "#{body}.json"))
    else
      body = "{}"
    end

    { status: status, headers: headers, body: body }
  end

  context "when the request is successful" do
    shared_examples_for "a job that imports constituencies" do
      it "imports constituencies" do
        expect { described_class.perform_now }.to change { Constituency.count }
      end

      describe "attribute assignment" do
        let(:constituency) { Constituency.first }
        let(:constituencies) { Constituency.pluck(:name) }

        before do
          described_class.perform_now
        end

        it "doesn't import old constituencies" do
          expect(constituencies).not_to include("Aberavon")
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

        before do
          stub_api_request_for("E18FF").to_return(api_response(:ok, "bethnal_green_and_bow"))
        end

        it "updates the constituency" do
          expect {
            described_class.perform_now
          }.to change {
            constituency.reload.example_postcode
          }.from("E27AX").to("E18FF")
        end
      end

      describe "error handling" do
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

    context "and the API returns a response with a BOM" do
      before do
        stub_api.to_return(reference_data_response(:ok, "constituencies_bom"))
      end

      it_behaves_like "a job that imports constituencies"
    end

    context "and the API returns a response without a BOM" do
      before do
        stub_api.to_return(reference_data_response(:ok, "constituencies_no_bom"))
      end

      it_behaves_like "a job that imports constituencies"
    end
  end

  context "when the request is unsuccessful" do
    context "because the API is not responding" do
      before do
        stub_api.to_timeout
      end

      it "doesn't import any constituencies" do
        expect { described_class.perform_now }.not_to change { Constituency.count }
      end
    end

    context "because the API connection is blocked" do
      before do
        stub_api.to_return(reference_data_response(:proxy_authentication_required))
      end

      it "doesn't import any constituencies" do
        expect { described_class.perform_now }.not_to change { Constituency.count }
      end
    end

    context "because the API can't be found" do
      before do
        stub_api.to_return(reference_data_response(:not_found))
      end

      it "doesn't import any constituencies" do
        expect { described_class.perform_now }.not_to change { Constituency.count }
      end
    end

    context "because the API can't find the resource" do
      before do
        stub_api.to_return(reference_data_response(:not_acceptable))
      end

      it "doesn't import any constituencies" do
        expect { described_class.perform_now }.not_to change { Constituency.count }
      end
    end

    context "because the API is returning an internal server error" do
      before do
        stub_api.to_return(reference_data_response(:internal_server_error))
      end

      it "doesn't import any constituencies" do
        expect { described_class.perform_now }.not_to change { Constituency.count }
      end
    end
  end
end
