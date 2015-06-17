require 'rails_helper'
include ActiveJob::TestHelper

RSpec.describe EmailThresholdResponseJob, type: :job do
  let(:email_requested_at) { Time.current }
  let(:petition) { FactoryGirl.create(:open_petition) }
  let(:signature) { FactoryGirl.create(:validated_signature, :petition => petition) }

  let(:mailer) { double.as_null_object }
  let(:logger) { double.as_null_object }

  before do
    petition.set_email_requested_at_for('government_response', to: email_requested_at)
    allow(petition).to receive_message_chain(:need_emailing, :find_each).and_yield(signature)
    allow(petition).to receive_message_chain(:need_emailing, :count => 0)
  end

  def perform_job(requested_at = email_requested_at)
    described_class.perform_now(petition, requested_at.getutc.iso8601, mailer, logger)
  end

  it "sends the notify_signer_of_threshold_response emails to each signatory of a petition" do
    expect(mailer).to receive(:notify_signer_of_threshold_response).with(petition, signature).and_return(mailer)
    perform_job
  end

  it "marks the signature with the 'government_response' last emailing time" do
    expect(signature).to receive(:set_email_sent_at_for).with('government_response', to: email_requested_at)
    perform_job
  end

  it 'uses a EmailPetitionSignatories::Worker to do the work' do
    worker = double
    expect(worker).to receive(:do_work!)
    expect(EmailPetitionSignatories::Worker).to receive(:new).with(instance_of(described_class), petition, email_requested_at.getutc.iso8601, anything).and_return worker
    perform_job
  end
end
