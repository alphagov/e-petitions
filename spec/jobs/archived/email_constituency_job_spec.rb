require 'rails_helper'
require_relative '../shared_examples'

RSpec.describe Archived::EmailConstituencyJob, type: :job do
  let(:mailshot_requested_at) { Time.current }
  let(:petition) { FactoryBot.create(:archived_petition) }
  let(:signature) { FactoryBot.create(:archived_signature, petition: petition) }
  let(:mailshot) { FactoryBot.create(:archived_petition_mailshot, petition: petition) }
  let(:scope) { { constituency_id: "3427" } }
  let(:arguments) { { petition: petition, mailshot: mailshot } }

  before do
    petition.set_email_requested_at_for('petition_mailshot', to: mailshot_requested_at)
    allow(petition).to receive_message_chain(:signatures_to_email_for, :find_each).and_yield(signature)
  end

  it_behaves_like "job to enqueue signatory mailing jobs"

  context "when the petition mailshot has been deleted" do
    before do
      mailshot.destroy
    end

    it "enqueues a job" do
      described_class.run_later_tonight(**arguments)
      expect(enqueued_jobs.size).to eq(1)
    end

    it "doesn't raise an error" do
      expect {
        perform_enqueued_jobs {
          described_class.run_later_tonight(**arguments)
        }
      }.not_to raise_error
    end

    it "doesn't send any email" do
      expect {
        perform_enqueued_jobs {
          described_class.run_later_tonight(**arguments)
        }
      }.not_to change { deliveries.size }
    end
  end
end
