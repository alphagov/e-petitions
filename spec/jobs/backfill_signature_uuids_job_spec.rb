require 'rails_helper'

RSpec.describe BackfillSignatureUuidsJob, type: :job do
  context "when the uuid column is nil" do
    let(:signature) { FactoryBot.create(:signature, email: "alice@example.com") }
    let(:uuid) { "6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6" }

    before do
      signature.update_column(:uuid, nil)
      signature.reload
    end

    it "updates the signature column" do
      expect {
        described_class.perform_now
      }.to change {
        signature.reload.uuid
      }.from(nil).to(uuid)
    end
  end

  context "when the uuid column is not nil" do
    let(:signature) { FactoryBot.create(:signature, email: "bob@example.com") }
    let(:uuid) { "6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6" }

    before do
      signature.update_column(:uuid, uuid)
      signature.reload
    end

    it "skips updating the uuid" do
      expect {
        described_class.perform_now
      }.not_to change {
        signature.reload.uuid
      }
    end
  end
end
