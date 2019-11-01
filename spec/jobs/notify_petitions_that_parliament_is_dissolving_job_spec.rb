require 'rails_helper'

RSpec.describe NotifyPetitionsThatParliamentIsDissolvingJob, type: :job do
  let(:petition) { FactoryBot.create(:open_petition, open_at: 3.months.ago) }

  let(:notify_petition_job) do
    {
      job: NotifyPetitionThatParliamentIsDissolvingJob,
      args: [{ "_aj_globalid" => "gid://epets/Petition/#{petition.id}" }],
      queue: "low_priority"
    }
  end

  before do
    expect(Petition).to receive_message_chain(:open_at_dissolution, :find_each).and_yield(petition)
  end

  it "enqueues a job for every petition that is open at dissolution" do
    expect {
      described_class.perform_now
    }.to change {
      enqueued_jobs
    }.from([]).to([notify_petition_job])
  end
end
