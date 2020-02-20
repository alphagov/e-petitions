require 'rails_helper'

RSpec.describe NotifyCreatorsThatModerationIsDelayedJob, type: :job do
  let(:petition) { FactoryBot.create(:sponsored_petition, :overdue, sponsors_signed: true) }
  let(:signature) { petition.creator }
  let(:subject) { "Moderation of your petition is delayed" }
  let(:body) { "Sorry, but moderation of your petition is delayed for reasons." }

  let(:notify_creator_job) do
    {
      job: NotifyCreatorThatModerationIsDelayedJob,
      args: [
        { "_aj_globalid" => "gid://welsh-pets/Signature/#{signature.id}" },
        "Moderation of your petition is delayed",
        "Sorry, but moderation of your petition is delayed for reasons."
      ],
      queue: "low_priority"
    }
  end

  before do
    expect(Petition).to receive_message_chain(:overdue_in_moderation, :find_each).and_yield(petition)
  end

  it "enqueues a job for every petition that is overdue" do
    expect {
      described_class.perform_now(subject, body)
    }.to change {
      enqueued_jobs
    }.from([]).to([notify_creator_job])
  end
end
