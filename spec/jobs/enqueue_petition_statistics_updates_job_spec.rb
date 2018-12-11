require 'rails_helper'

RSpec.describe EnqueuePetitionStatisticsUpdatesJob, type: :job do
  let(:timestamp) { 1.hour.ago.iso8601 }

  it "only enqueues jobs for petitions signed in the last hour" do
    FactoryBot.create(:open_petition, last_signed_at: 2.hours.ago)
    FactoryBot.create(:open_petition, last_signed_at: 30.minutes.ago)
    FactoryBot.create(:open_petition, last_signed_at: 15.minutes.ago)

    expect {
      described_class.perform_now(timestamp)
    }.to change {
      enqueued_jobs.size
    }.from(0).to(2)
  end

  it "enqueues an UpdatePetitionStatisticsJob job" do
    petition = FactoryBot.create(:open_petition, last_signed_at: 15.minutes.ago)

    update_statistics_job = {
      job: UpdatePetitionStatisticsJob,
      args: [{ "_aj_globalid" => "gid://epets/Petition/#{petition.id}" }],
      queue: "low_priority"
    }

    expect {
      described_class.perform_now(timestamp)
    }.to change {
      enqueued_jobs
    }.from([]).to([update_statistics_job])
  end
end
