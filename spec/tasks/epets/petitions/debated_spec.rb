require 'rails_helper'

RSpec.describe "epets:petitions:debated", type: :task do
  around do |example|
    freeze_time { example.run }
  end

  let(:parliament) { Parliament.instance }
  let(:tomorrow) { Date.tomorrow }
  let(:midnight) { tomorrow.beginning_of_day }

  context "when parliament is open" do
    before do
      allow(parliament).to receive(:dissolution_at).and_return(nil)
    end

    it "enqueues the DebatedPetitionsJob to run at midnight" do
      expect {
        subject.invoke
      }.to have_enqueued_job(
        DebatedPetitionsJob
      ).on_queue(:high_priority).at(midnight).with(tomorrow.iso8601)
    end
  end

  context "when parliament has dissolved less than 48 hours ago" do
    before do
      allow(parliament).to receive(:dissolution_at).and_return(24.hours.ago)
    end

    it "enqueues the DebatedPetitionsJob to run at midnight" do
      expect {
        subject.invoke
      }.to have_enqueued_job(
        DebatedPetitionsJob
      ).on_queue(:high_priority).at(midnight).with(tomorrow.iso8601)
    end
  end

  context "when parliament has dissolved more than 48 hours ago" do
    before do
      allow(parliament).to receive(:dissolution_at).and_return(72.hours.ago)
    end

    it "doesn't enqueue the DebatedPetitionsJob" do
      expect {
        subject.invoke
      }.not_to have_enqueued_job(
        DebatedPetitionsJob
      )
    end
  end
end
