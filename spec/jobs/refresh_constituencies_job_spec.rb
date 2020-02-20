require 'rails_helper'

RSpec.describe RefreshConstituenciesJob, type: :job do
  context "when an MP has vacated their seat" do
    let(:constituency) do
      FactoryBot.create(:constituency, :coventry_north_east)
    end

    before do
      stub_api_request_for("CV21PH").to_return(api_response(:ok, "coventry_north_east"))
    end

    it "updates the existing constituencies" do
      expect {
        described_class.perform_now
      }.to change {
        constituency.reload.mp_name
      }.from("Colleen Fletcher MP").to(nil)
    end
  end
end
