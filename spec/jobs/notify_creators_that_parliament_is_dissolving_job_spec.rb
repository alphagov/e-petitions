require 'rails_helper'

RSpec.describe NotifyCreatorsThatParliamentIsDissolvingJob, type: :job do
  let(:petition) { FactoryBot.create(:open_petition, open_at: 3.months.ago) }
  let(:signature) { petition.creator }

  let(:notify_creator_job) do
    {
      job: NotifyCreatorThatParliamentIsDissolvingJob,
      args: [{ "_aj_globalid" => "gid://epets/Signature/#{signature.id}" }],
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
    }.from([]).to([notify_creator_job])
  end
end
