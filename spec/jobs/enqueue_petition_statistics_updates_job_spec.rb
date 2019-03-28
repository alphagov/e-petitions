require 'rails_helper'

RSpec.describe EnqueuePetitionStatisticsUpdatesJob, type: :job do
  let(:timestamp) { 1.day.ago.iso8601 }

  it "only enqueues jobs for petitions signed in the last day" do
    FactoryBot.create(:open_petition, last_signed_at: 6.hours.ago)
    FactoryBot.create(:open_petition, last_signed_at: 36.hours.ago)
    FactoryBot.create(:open_petition, last_signed_at: 18.hours.ago)

    expect {
      described_class.perform_now(timestamp)
    }.to change {
      enqueued_jobs.size
    }.from(0).to(2)
  end

  describe "configuration" do
    before do
      FactoryBot.create(:open_petition, last_signed_at: 6.hours.ago)
    end

    context "when the daily update job is disabled" do
      before do
        allow(Site).to receive(:disable_daily_update_statistics_job?).and_return(true)
      end

      it "doesn't enqueue any jobs" do
        expect {
          described_class.perform_now(timestamp)
        }.not_to have_enqueued_job(UpdatePetitionStatisticsJob)
      end
    end

    context "when the daily update job is enabled" do
      before do
        allow(Site).to receive(:disable_daily_update_statistics_job?).and_return(false)
      end

      it "enqueues an UpdatePetitionStatisticsJob job" do
        expect {
          described_class.perform_now(timestamp)
        }.to have_enqueued_job(UpdatePetitionStatisticsJob)
      end
    end
  end
end
