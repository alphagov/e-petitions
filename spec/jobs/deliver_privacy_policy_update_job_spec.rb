require "rails_helper"

RSpec.describe DeliverPrivacyPolicyUpdateJob, type: :job do
  describe "perform" do
    let(:signature) { FactoryBot.create(:signature) }

    it "sends an email" do
      expect {
        described_class.perform_now(signature)
      }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end
  end
end
