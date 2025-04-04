require 'rails_helper'
require_relative 'shared_examples'

RSpec.describe DeliverDebateOutcomeEmailJob, type: :job do
  let(:requested_at) { Time.current.change(usec: 0) }
  let(:requested_at_as_string) { requested_at.getutc.iso8601(6) }

  let(:petition) { FactoryBot.create(:debated_petition) }
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

  context "when the signature is the creator" do
    before do
      allow(signature).to receive(:creator?).and_return(true)
    end

    context "and the petition is debated" do
      let(:petition) { FactoryBot.create(:debated_petition) }

      it "uses the correct mailer method to generate the email" do
        expect(subject).to receive_message_chain(:mailer, :notify_creator_of_positive_debate_outcome).with(petition, signature).and_return double.as_null_object
        subject.perform(**arguments)
      end
    end

    context "and the petition is not debated" do
      let(:petition) { FactoryBot.create(:not_debated_petition) }

      it "uses the correct mailer method to generate the email" do
        expect(subject).to receive_message_chain(:mailer, :notify_creator_of_negative_debate_outcome).with(petition, signature).and_return double.as_null_object
        subject.perform(**arguments)
      end
    end
  end

  context "when the signature is not the creator" do
    before do
      allow(signature).to receive(:creator?).and_return(false)
    end

    context "and the petition is debated" do
      let(:petition) { FactoryBot.create(:debated_petition) }

      it "uses the correct mailer method to generate the email" do
        expect(subject).to receive_message_chain(:mailer, :notify_signer_of_positive_debate_outcome).with(petition, signature).and_return double.as_null_object
        subject.perform(**arguments)
      end
    end

    context "and the petition is not debated" do
      let(:petition) { FactoryBot.create(:not_debated_petition) }

      it "uses the correct mailer method to generate the email" do
        expect(subject).to receive_message_chain(:mailer, :notify_signer_of_negative_debate_outcome).with(petition, signature).and_return double.as_null_object
        subject.perform(**arguments)
      end
    end
  end
end
