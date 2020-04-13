require 'rails_helper'
require_relative 'shared_examples'

RSpec.describe DeliverDebateOutcomeEmailJob, type: :job do
  let(:requested_at) { Time.current.change(usec: 0) }
  let(:requested_at_as_string) { requested_at.getutc.iso8601(6) }

  let(:petition) { FactoryBot.create(:debated_petition) }
  let(:outcome) { petition.debate_outcome }
  let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
  let(:timestamp_name) { 'debate_outcome' }

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

  context "when the petition was debated" do
    let(:petition) { FactoryBot.create(:debated_petition) }

    context "when the signature is the creator" do
      before do
        allow(signature).to receive(:creator?).and_return(true)
      end

      it "uses the correct notify job to generate the email" do
        expect {
          subject.perform(**arguments)
        }.to have_enqueued_job(NotifyCreatorOfPositiveDebateOutcomeEmailJob).with(signature, outcome)
      end
    end

    context "when the signature is not the creator" do
      before do
        allow(signature).to receive(:creator?).and_return(false)
      end

      it "uses the correct notify job to generate the email" do
        expect {
          subject.perform(**arguments)
        }.to have_enqueued_job(NotifySignerOfPositiveDebateOutcomeEmailJob).with(signature, outcome)
      end
    end
  end

  context "when the petition wasn't debated" do
    let(:petition) { FactoryBot.create(:not_debated_petition) }

    context "when the signature is the creator" do
      before do
        allow(signature).to receive(:creator?).and_return(true)
      end

      it "uses the correct notify job to generate the email" do
        expect {
          subject.perform(**arguments)
        }.to have_enqueued_job(NotifyCreatorOfNegativeDebateOutcomeEmailJob).with(signature, outcome)
      end
    end

    context "when the signature is not the creator" do
      before do
        allow(signature).to receive(:creator?).and_return(false)
      end

      it "uses the correct notify job to generate the email" do
        expect {
          subject.perform(**arguments)
        }.to have_enqueued_job(NotifySignerOfNegativeDebateOutcomeEmailJob).with(signature, outcome)
      end
    end
  end
end
