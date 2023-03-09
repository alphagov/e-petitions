require 'rails_helper'

RSpec.describe Petition::Statistics, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:petition_statistics)).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id]) }
  end

  describe "callbacks" do
    let!(:petition) { FactoryBot.create(:open_petition) }

    it "enqueues a job on create" do
      expect {
        petition.create_statistics!
      }.to change {
        enqueued_jobs.size
      }.by(1)
    end

    it "doesn't enqueue a job on update" do
      petition.create_statistics!

      expect {
        petition.statistics.refresh!
      }.not_to change {
        enqueued_jobs.size
      }
    end
  end

  describe "#refreshed?" do
    context "when the statistics have never been updated" do
      let(:statistics) { FactoryBot.build(:petition_statistics, refreshed_at: nil) }

      it "returns false" do
        expect(statistics.refreshed?).to eq(false)
      end
    end

    context "when the statistics have been updated" do
      let(:statistics) { FactoryBot.build(:petition_statistics, refreshed_at: 1.hour.ago) }

      it "returns true" do
        expect(statistics.refreshed?).to eq(true)
      end
    end
  end

  describe "#refresh!" do
    let!(:petition) { FactoryBot.create(:open_petition, creator_attributes: { notify_by_email: false }) }
    let!(:statistics) { FactoryBot.create(:petition_statistics, petition: petition, refreshed_at: nil) }

    it "updates the refreshed_at timestamp" do
      expect {
        statistics.refresh!
      }.to change {
        statistics.reload.refreshed_at
      }.from(nil).to(be_within(1.second).of(Time.current))
    end

    context "when there are no duplicate emails" do
      it "updates the duplicate_emails count" do
        expect {
          statistics.refresh!
        }.to change {
          statistics.reload.duplicate_emails
        }.from(nil).to(0)
      end
    end

    context "when there are duplicate emails" do
      let!(:alice) { FactoryBot.create(:pending_signature, petition: petition, name: "Alice", email: "aliceandbob@example.com") }
      let!(:bob) { FactoryBot.create(:pending_signature, petition: petition, name: "Bob", email: "aliceandbob@example.com") }

      it "updates the duplicate_emails count" do
        perform_enqueued_jobs do
          alice.validate!
          bob.validate!
        end

        expect {
          statistics.refresh!
        }.to change {
          statistics.reload.duplicate_emails
        }.from(nil).to(1)
      end
    end

    context "when there are no pending signatures" do
      before do
        FactoryBot.create(:validated_signature, petition: petition)
      end

      it "updates the pending_rate value" do
        expect {
          statistics.refresh!
        }.to change {
          statistics.reload.pending_rate
        }.from(nil).to(0)
      end
    end

    context "when there are pending signatures" do
      before do
        FactoryBot.create(:pending_signature, petition: petition)
      end

      it "updates the pending_rate value" do
        expect {
          statistics.refresh!
        }.to change {
          statistics.reload.pending_rate
        }.from(nil).to(50)
      end
    end

    context "when there are no subscribed signatures" do
      before do
        FactoryBot.create(:validated_signature, petition: petition, notify_by_email: false)
      end

      it "updates the subscribers value" do
        expect {
          statistics.refresh!
        }.to change {
          statistics.reload.subscribers
        }.from(nil).to(0)
      end
    end

    context "when there are subscribed signatures" do
      before do
        FactoryBot.create(:validated_signature, petition: petition, notify_by_email: true)
      end

      it "updates the subscribers value" do
        expect {
          statistics.refresh!
        }.to change {
          statistics.reload.subscribers
        }.from(nil).to(1)
      end
    end
  end

  describe "#subscribers?" do
    context "when the subscriber count is nil" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: nil) }

      it "returns false" do
        expect(subject.subscribers?).to eq(false)
      end
    end

    context "when the subscriber count is zero" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: 0) }

      it "returns true" do
        expect(subject.subscribers?).to eq(true)
      end
    end

    context "when the subscriber count is more than zero" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: 1) }

      it "returns true" do
        expect(subject.subscribers?).to eq(true)
      end
    end
  end

  describe "#subscribers?" do
    context "when the subscriber count is nil" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: nil) }

      it "returns false" do
        expect(subject.subscribers?).to eq(false)
      end
    end

    context "when the subscriber count is zero" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: 0) }

      it "returns true" do
        expect(subject.subscribers?).to eq(true)
      end
    end

    context "when the subscriber count is more than zero" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: 1) }

      it "returns true" do
        expect(subject.subscribers?).to eq(true)
      end
    end
  end

  describe "#subscriber_count" do
    context "when the subscriber count is nil" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: nil) }

      it "returns nil" do
        expect(subject.subscriber_count).to be_nil
      end
    end

    context "when the subscriber count is not nil" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: 1234) }

      it "returns a formatted count" do
        expect(subject.subscriber_count).to eq("1,234")
      end
    end
  end

  describe "#subscription_rate" do
    context "when the subscriber count is nil" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: nil) }

      before do
        expect(subject.petition).not_to receive(:signature_count?)
        expect(subject.petition).not_to receive(:signature_count)
      end

      it "returns nil" do
        expect(subject.subscription_rate).to be_nil
      end
    end

    context "when the subscriber count is zero and the signature count is zero" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: 0) }

      before do
        expect(subject.petition).to receive(:signature_count?).and_return(false)
        expect(subject.petition).not_to receive(:signature_count)
      end

      it "returns a formatted percentage" do
        expect(subject.subscription_rate).to be_nil
      end
    end

    context "when the subscriber count is zero" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: 0) }

      before do
        expect(subject.petition).to receive(:signature_count?).and_return(true)
        expect(subject.petition).to receive(:signature_count).and_return(99)
      end

      it "returns a formatted percentage" do
        expect(subject.subscription_rate).to eq("0.0%")
      end
    end

    context "when the subscriber count is more than zero" do
      subject { FactoryBot.create(:petition_statistics, :refreshed, subscribers: 66) }

      before do
        expect(subject.petition).to receive(:signature_count?).and_return(true)
        expect(subject.petition).to receive(:signature_count).and_return(99)
      end

      it "returns a formatted percentage" do
        expect(subject.subscription_rate).to eq("66.7%")
      end
    end
  end
end
