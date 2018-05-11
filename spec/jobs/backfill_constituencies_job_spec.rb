require 'rails_helper'

RSpec.describe BackfillConstituenciesJob, type: :job do
  context "when the constituency_id column is nil" do
    let(:signature) { FactoryBot.create(:validated_signature, constituency_id: nil) }

    it "updates the constituency_id column" do
      expect {
        described_class.perform_now
      }.to change {
        signature.reload.constituency_id
      }.from(nil).to("3415")
    end
  end

  context "when the constituency_id column is not nil" do
    let(:signature) { FactoryBot.create(:validated_signature, constituency_id: "1234") }

    it "skips updating the constituency_id" do
      expect {
        described_class.perform_now
      }.not_to change {
        signature.reload.constituency_id
      }
    end
  end

  context "when limited in scope by id" do
    let!(:signature_1) { FactoryBot.create(:validated_signature, constituency_id: nil) }
    let!(:signature_2) { FactoryBot.create(:validated_signature, constituency_id: nil) }

    it "updates those in scope" do
      expect {
        described_class.perform_now(id: signature_1.id)
      }.to change {
        signature_2.reload.constituency_id
      }.from(nil).to("3415")
    end

    it "doesn't update those out of scope" do
      expect {
        described_class.perform_now(id: signature_1.id)
      }.not_to change {
        signature_1.reload.constituency_id
      }
    end
  end

  context "when limited in scope by date" do
    let!(:signature_1) { FactoryBot.create(:validated_signature, constituency_id: nil, validated_at: 2.weeks.ago) }
    let!(:signature_2) { FactoryBot.create(:validated_signature, constituency_id: nil, validated_at: 1.day.ago) }

    it "updates those in scope" do
      expect {
        described_class.perform_now(since: 1.week.ago)
      }.to change {
        signature_2.reload.constituency_id
      }.from(nil).to("3415")
    end

    it "doesn't update those out of scope" do
      expect {
        described_class.perform_now(since: 1.week.ago)
      }.not_to change {
        signature_1.reload.constituency_id
      }
    end
  end

  context "when limited in scope by id and date" do
    let!(:signature_1) { FactoryBot.create(:validated_signature, constituency_id: nil, validated_at: 2.weeks.ago) }
    let!(:signature_2) { FactoryBot.create(:validated_signature, constituency_id: nil, validated_at: 1.day.ago) }
    let!(:signature_3) { FactoryBot.create(:validated_signature, constituency_id: nil, validated_at: 1.day.ago) }

    it "updates those in scope" do
      expect {
        described_class.perform_now(id: signature_2.id, since: 1.week.ago)
      }.to change {
        signature_3.reload.constituency_id
      }.from(nil).to("3415")
    end

    it "doesn't update those out of scope" do
      expect {
        described_class.perform_now(since: 1.week.ago)
      }.not_to change {
        signature_1.reload.constituency_id
      }
    end

    it "doesn't update those out of scope by date" do
      expect {
        described_class.perform_now(id: signature_2.id, since: 1.week.ago)
      }.not_to change {
        signature_1.reload.constituency_id
      }
    end

    it "doesn't update those out of scope by id" do
      expect {
        described_class.perform_now(id: signature_2.id, since: 1.week.ago)
      }.not_to change {
        signature_2.reload.constituency_id
      }
    end
  end
end
