require 'rails_helper'

RSpec.describe DeletePetitionsJob, type: :job do
  it "enqueues a job for every petition" do
    FactoryBot.create(:closed_petition, archived_at: 1.day.ago)
    FactoryBot.create(:stopped_petition, archived_at: 1.day.ago)
    FactoryBot.create(:rejected_petition, archived_at: 1.day.ago)
    FactoryBot.create(:hidden_petition, archived_at: 1.day.ago)

    expect {
      described_class.perform_now
    }.to change {
      enqueued_jobs.size
    }.from(0).to(4)
  end

  it "enqueues an DeletePetitionJob job" do
    petition = FactoryBot.create(:closed_petition, archived_at: 1.day.ago)

    delete_petition_job = {
      job: DeletePetitionJob,
      args: [{ "_aj_globalid" => "gid://epets/Petition/#{petition.id}" }],
      queue: "high_priority"
    }

    expect {
      described_class.perform_now
    }.to change {
      enqueued_jobs
    }.from([]).to([delete_petition_job])
  end

  it "raises a RuntimeError unless all petitions are archived" do
    FactoryBot.create(:closed_petition, archived_at: 1.day.ago)
    FactoryBot.create(:closed_petition, archived_at: nil)

    expect {
      described_class.perform_now
    }.to raise_error(RuntimeError, /result in a loss of data/)
  end
end
