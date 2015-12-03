require 'rails_helper'
require_relative 'shared_examples'

RSpec.describe EmailPetitionersJob, type: :job do
  let(:email_requested_at) { Time.current }
  let(:petition) { FactoryGirl.create(:open_petition) }
  let(:signature) { FactoryGirl.create(:validated_signature, :petition => petition) }
  let(:email) { FactoryGirl.create(:petition_email, petition: petition) }
  let(:arguments) { { petition: petition, email: email } }

  before do
    petition.set_email_requested_at_for('petition_email', to: email_requested_at)
    allow(petition).to receive_message_chain(:signatures_to_email_for, :find_each).and_yield(signature)
  end

  it_behaves_like "job to enqueue signatory mailing jobs"

  context "when the petition email has been deleted" do
    before do
      email.destroy
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
