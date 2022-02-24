require "rails_helper"

RSpec.describe DeliverPrivacyPolicyUpdateJob, type: :job do
  describe "perform" do
    let(:signature) { FactoryBot.create(:signature) }

    let(:privacy_notification) do
      FactoryBot.create(:privacy_notification, signature: signature)
    end

    it "sends an email" do
      expect {
        described_class.perform_now(privacy_notification)
      }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end
  end
end
