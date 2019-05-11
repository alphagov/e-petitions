require 'rails_helper'

RSpec.describe BackfillCanonicalEmailsJob, type: :job do
  before do
    allow(Site).to receive(:disable_plus_address_check?).and_return(true)
  end

  context "when the canonical_email column is nil" do
    let(:signature) { FactoryBot.create(:signature, email: "alice+foo@example.com") }
    let(:canonical_email) { "alice@example.com" }

    before do
      signature.update_column(:canonical_email, nil)
      signature.reload

      expect_any_instance_of(Signature).to receive(:update_canonical_email).and_call_original
    end

    it "updates the canonical_email column" do
      expect {
        described_class.perform_now
      }.to change {
        signature.reload.canonical_email
      }.from(nil).to(canonical_email)
    end
  end

  context "when the canonical_email column is not nil" do
    let(:signature) { FactoryBot.create(:signature, email: "bob+foo@example.com") }
    let(:canonical_email) { "bob@example.com" }

    before do
      signature.update_column(:uuid, canonical_email)
      signature.reload

      expect_any_instance_of(Signature).not_to receive(:update_canonical_email)
    end

    it "skips updating the canonical_email column" do
      expect {
        described_class.perform_now
      }.not_to change {
        signature.reload.canonical_email
      }
    end
  end
end
