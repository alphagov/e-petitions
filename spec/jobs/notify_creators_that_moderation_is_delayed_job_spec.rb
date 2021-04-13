require 'rails_helper'

RSpec.describe NotifyCreatorsThatModerationIsDelayedJob, type: :job do
  let(:petition) { FactoryBot.create(:sponsored_petition, :overdue, sponsors_signed: true) }
  let(:signature) { petition.creator }
  let(:subject) { "Moderation of your petition is delayed" }
  let(:body) { "Sorry, but moderation of your petition is delayed for reasons." }

  before do
    expect(Petition).to receive_message_chain(:overdue_in_moderation, :find_each).and_yield(petition)
  end

  it "enqueues a job for every petition that is open at dissolution" do
    expect {
      described_class.perform_now(subject, body)
    }.to have_enqueued_job(
      NotifyCreatorThatModerationIsDelayedJob
    ).on_queue(:low_priority).with(
      signature,
      "Moderation of your petition is delayed",
      "Sorry, but moderation of your petition is delayed for reasons."
    )
  end
end
