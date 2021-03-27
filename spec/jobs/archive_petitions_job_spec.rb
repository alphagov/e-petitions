require 'rails_helper'

RSpec.describe ArchivePetitionsJob, type: :job do
  it "enqueues a job for every petition" do
    FactoryBot.create(:closed_petition)
    FactoryBot.create(:stopped_petition)
    FactoryBot.create(:rejected_petition)
    FactoryBot.create(:hidden_petition)

    expect {
      described_class.perform_now
    }.to change {
      enqueued_jobs.size
    }.from(0).to(4)
  end

  it "enqueues an ArchivePetitionJob job" do
    petition = FactoryBot.create(:closed_petition)

    expect {
      described_class.perform_now
    }.to have_enqueued_job(
      ArchivePetitionJob
    ).on_queue(:high_priority).with(petition)
  end

  it "updates the archiving_started_at timestamp" do
    petition = FactoryBot.create(:closed_petition)

    expect {
      described_class.perform_now
    }.to change {
      petition.reload.archiving_started_at
    }.from(nil).to(be_within(1.second).of(Time.current))
  end

  it "doesn't enqueue a job for a petition that's already archived" do
    FactoryBot.create(:closed_petition, archived_at: 1.day.ago)

    expect {
      described_class.perform_now
    }.not_to change {
      enqueued_jobs.size
    }
  end
end
