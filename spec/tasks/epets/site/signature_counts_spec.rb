require 'rails_helper'

RSpec.describe "epets:site:signature_counts", type: :task do
  around do |example|
    freeze_time { example.run }
  end

  let(:parliament) { Parliament.instance }
  let(:site) { Site.instance }

  context "when parliament is open" do
    before do
      allow(parliament).to receive(:dissolution_at).and_return(nil)
    end

    context "and signature counting is enabled" do
      before do
        allow(site).to receive(:update_signature_counts).and_return(true)
      end

      context "and the last count was less than 15 minutes ago" do
        before do
          allow(site).to receive(:signature_count_updated_at).and_return(10.minutes.ago)
        end

        it "doesn't enqueue the UpdateSignatureCountsJob" do
          expect {
            subject.invoke
          }.not_to have_enqueued_job(
            UpdateSignatureCountsJob
          )
        end
      end

      context "and the last count was more than 15 minutes ago" do
        before do
          allow(site).to receive(:signature_count_updated_at).and_return(20.minutes.ago)
        end

        it "enqueues the UpdateSignatureCountsJob" do
          expect {
            subject.invoke
          }.to have_enqueued_job(
            UpdateSignatureCountsJob
          ).on_queue(:highest_priority)
        end
      end
    end

    context "and signature counting is disabled" do
      before do
        allow(site).to receive(:update_signature_counts).and_return(false)
        allow(site).to receive(:signature_count_updated_at).and_return(30.minutes.ago)
      end

      it "doesn't enqueue the UpdateSignatureCountsJob" do
        expect {
          subject.invoke
        }.not_to have_enqueued_job(
          UpdateSignatureCountsJob
        )
      end
    end
  end

  context "when parliament has dissolved less than 48 hours ago" do
    before do
      allow(parliament).to receive(:dissolution_at).and_return(24.hours.ago)
    end

    context "and signature counting is enabled" do
      before do
        allow(site).to receive(:update_signature_counts).and_return(true)
      end

      context "and the last count was less than 15 minutes ago" do
        before do
          allow(site).to receive(:signature_count_updated_at).and_return(10.minutes.ago)
        end

        it "doesn't enqueue the UpdateSignatureCountsJob" do
          expect {
            subject.invoke
          }.not_to have_enqueued_job(
            UpdateSignatureCountsJob
          )
        end
      end

      context "and the last count was more than 15 minutes ago" do
        before do
          allow(site).to receive(:signature_count_updated_at).and_return(20.minutes.ago)
        end

        it "enqueues the UpdateSignatureCountsJob" do
          expect {
            subject.invoke
          }.to have_enqueued_job(
            UpdateSignatureCountsJob
          ).on_queue(:highest_priority)
        end
      end
    end

    context "and signature counting is disabled" do
      before do
        allow(site).to receive(:update_signature_counts).and_return(false)
        allow(site).to receive(:signature_count_updated_at).and_return(30.minutes.ago)
      end

      it "doesn't enqueue the UpdateSignatureCountsJob" do
        expect {
          subject.invoke
        }.not_to have_enqueued_job(
          UpdateSignatureCountsJob
        )
      end
    end
  end

  context "when parliament has dissolved more than 48 hours ago" do
    before do
      allow(parliament).to receive(:dissolution_at).and_return(72.hours.ago)
      allow(site).to receive(:update_signature_counts).and_return(true)
      allow(site).to receive(:signature_count_updated_at).and_return(30.minutes.ago)
    end

    it "doesn't enqueue the UpdateSignatureCountsJob" do
      expect {
        subject.invoke
      }.not_to have_enqueued_job(
        UpdateSignatureCountsJob
      )
    end
  end
end
