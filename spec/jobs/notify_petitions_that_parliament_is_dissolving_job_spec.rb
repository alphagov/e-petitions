require 'rails_helper'

RSpec.describe NotifyPetitionsThatParliamentIsDissolvingJob, type: :job do
  let(:petition) { FactoryBot.create(:open_petition, open_at: 3.months.ago) }

  before do
    expect(Petition).to receive_message_chain(:open_at_dissolution, :find_each).and_yield(petition)
  end

  it "enqueues a job for every petition that is open at dissolution" do
    expect {
      described_class.perform_now
    }.to have_enqueued_job(
      NotifyPetitionThatParliamentIsDissolvingJob
    ).on_queue(:low_priority).with(petition)
  end
end
