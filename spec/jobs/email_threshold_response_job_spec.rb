require 'net/smtp'
require 'rails_helper'
include ActiveJob::TestHelper

RSpec.describe EmailThresholdResponseJob, type: :job do
  let(:email_requested_at) { Time.now }
  let(:petition) { FactoryGirl.create(:open_petition, :email_requested_at => email_requested_at) }
  let(:signature) { FactoryGirl.create(:validated_signature, :petition => petition) }

  let(:mailer) { double.as_null_object }
  let(:logger) { double.as_null_object }

  before do
    allow(petition).to receive_message_chain(:need_emailing, :find_each).and_yield(signature)
    allow(petition).to receive_message_chain(:need_emailing, :count => 0)
  end

  def perform_job
    EmailThresholdResponseJob.perform_now(petition, email_requested_at, mailer, logger)
  end

  it "sends emails to each signatory of a petition" do
    expect(mailer).to receive(:notify_signer_of_threshold_response).with(petition, signature).and_return(mailer)
    perform_job
  end

  it "doesn't run unless it's the latest request" do
    expect(mailer).not_to receive(:notify_signer_of_threshold_response)
    requested_at = Time.now - 1000
    EmailThresholdResponseJob.perform_now(petition, requested_at, mailer, logger)
  end

  it "marks the signature with the last emailing time" do
    expect(signature).to receive(:update_attribute).with(:last_emailed_at, email_requested_at)
    perform_job
  end

  context "email sending fails" do
    before do
      allow(mailer).to receive(:notify_signer_of_threshold_response).and_raise(Errno::ECONNREFUSED)
    end

    it "should catch the error" do
      expect { perform_job }.not_to raise_error
    end

    it "skips that signature and moves on" do
      expect(signature).not_to receive(:update_attribute).with(:last_emailed_at, email_requested_at)
      perform_job
    end

    context "with more emails to process" do
      before do
        allow(petition).to receive_message_chain(:need_emailing, :count => 1)
      end

      it "raises an error at the end of the run to force a retry" do
        expect { perform_job }.to raise_error(PleaseRetryEmailJob)
      end

      it "does not log the exception as an error" do
        allow(petition).to receive_message_chain(:need_emailing, :count => 1)
        expect(logger).not_to receive(:error)
        expect { perform_job }.to raise_error
      end
    end
  end

  context "email fails with an SMTPError" do
    before do
      allow(mailer).to receive(:notify_signer_of_threshold_response).and_raise(Net::SMTPFatalError)
    end

    it "should catch the error" do
      expect { perform_job }.not_to raise_error
    end

    it "skips that signature and moves on" do
      expect(signature).not_to receive(:update_attribute).with(:last_emailed_at, email_requested_at)
      perform_job
    end
  end

  context "update attribute fails" do
    it "lets other exceptions through" do
      allow(signature).to receive(:update_attribute).and_raise(Exception)
      expect { perform_job }.to raise_error
    end
  end
end
