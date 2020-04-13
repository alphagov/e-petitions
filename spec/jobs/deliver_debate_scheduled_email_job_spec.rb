require 'rails_helper'
require_relative 'shared_examples'

RSpec.describe DeliverDebateScheduledEmailJob, type: :job do
  let(:requested_at) { Time.current.change(usec: 0) }
  let(:requested_at_as_string) { requested_at.getutc.iso8601(6) }

  let(:petition) { FactoryBot.create(:scheduled_debate_petition) }
  let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
  let(:timestamp_name) { 'debate_scheduled' }

  let :arguments do
    {
      signature: signature,
      timestamp_name: timestamp_name,
      petition: petition,
      requested_at: requested_at_as_string
    }
  end

  before do
    petition.set_email_requested_at_for(timestamp_name, to: requested_at)
  end

  it_behaves_like "a job to send an signatory email"

  context "when the signature is the creator" do
    before do
      allow(signature).to receive(:creator?).and_return(true)
    end

    it "uses the correct notify job to generate the email" do
      expect {
        subject.perform(**arguments)
      }.to have_enqueued_job(NotifyCreatorOfDebateScheduledEmailJob).with(signature)
    end
  end

  context "when the signature is not the creator" do
    before do
      allow(signature).to receive(:creator?).and_return(false)
    end

    it "uses the correct notify job to generate the email" do
      expect {
        subject.perform(**arguments)
      }.to have_enqueued_job(NotifySignerOfDebateScheduledEmailJob).with(signature)
    end
  end
end
