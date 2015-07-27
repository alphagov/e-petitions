require 'rails_helper'
require_relative '../shared_examples'

RSpec.describe EmailDeliveryJobs::ThresholdResponse, type: :job do
  let(:email_requested_at) { Time.current }
  let(:petition) { FactoryGirl.create(:responded_petition) }
  let(:signature) { FactoryGirl.create(:validated_signature, petition: petition) }
  let(:timestamp_name) { 'government_response' }

  before do
    petition.set_email_requested_at_for(timestamp_name, to: email_requested_at)
  end

  it_behaves_like "a job to send an signatory email"

  it "uses the correct mailer method to generate the email" do
    expect(subject).to receive_message_chain(:mailer, :notify_signer_of_threshold_response).with(petition, signature).and_return double.as_null_object
    subject.perform(
      signature: signature,
      timestamp_name: timestamp_name,
      petition: petition,
      requested_at_as_string: email_requested_at.getutc.iso8601
    )
  end
end
