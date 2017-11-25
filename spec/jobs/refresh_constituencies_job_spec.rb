require 'rails_helper'

RSpec.describe RefreshConstituenciesJob, type: :job do
  context "when Parliament has dissolved" do
    let(:constituency_1) do
      FactoryBot.create(:constituency, :coventry_north_east)
    end

    let(:constituency_2) do
      FactoryBot.create(:constituency, :sheffield_brightside_and_hillsborough)
    end

    before do
      stub_api_request_for("CV21PH").to_return(api_response(:ok, "coventry_north_east"))
      stub_api_request_for("S61AR").to_return(api_response(:ok, "sheffield_brightside_and_hillsborough"))
    end

    it "updates the existing constituencies" do
      expect {
        described_class.perform_now
      }.to change {
        [
          constituency_1.reload.mp_name,
          constituency_2.reload.mp_name
        ]
      }.from(["Colleen Fletcher MP", "Gill Furniss"]).to([nil, nil])
    end
  end
end
