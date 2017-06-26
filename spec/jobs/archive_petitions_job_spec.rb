require 'rails_helper'

RSpec.describe ArchivePetitionsJob, type: :job do
  it "enqueues a job for every petition" do
    FactoryGirl.create(:closed_petition)
    FactoryGirl.create(:stopped_petition)
    FactoryGirl.create(:rejected_petition)
    FactoryGirl.create(:hidden_petition)

    expect {
      described_class.perform_now
    }.to change {
      enqueued_jobs.size
    }.from(0).to(4)
  end

  it "enqueues an ArchivePetitionJob job" do
    petition = FactoryGirl.create(:closed_petition)

    archive_petition_job = {
      job: ArchivePetitionJob,
      args: [{ "_aj_globalid" => "gid://epets/Petition/#{petition.id}" }],
      queue: "high_priority"
    }

    expect {
      described_class.perform_now
    }.to change {
      enqueued_jobs
    }.from([]).to([archive_petition_job])
  end

  it "doesn't enqueue a job for a petition that's already archived" do
    FactoryGirl.create(:closed_petition, archived_at: 1.day.ago)

    expect {
      described_class.perform_now
    }.not_to change {
      enqueued_jobs.size
    }
  end
end
