require 'app/jobs/email_threshold_response_job'
require 'net/smtp'

describe EmailThresholdResponseJob do
  let(:email_requested_at) { Time.now }
  let(:petition) { double(:petition, :email_requested_at => email_requested_at, :title => 'my petition') }
  let(:signature) { double(:signature, :email => 'foo@bar.com', :update_attribute => nil) }

  let(:model) { double(:model, :find => petition) }
  let(:mailer) { double.as_null_object }
  let(:logger) { double.as_null_object }
  let(:now) { double }

  before do
    petition.stub_chain(:need_emailing, :find_each).and_yield(signature)
    petition.stub_chain(:need_emailing, :count => 0)
  end

  def perform_job
    job = EmailThresholdResponseJob.new(1, email_requested_at, model, mailer)
    job.stub(:logger => logger)
    job.perform
  end

  it "sends emails to each signatory of a petition" do
    mailer.should_receive(:notify_signer_of_threshold_response).with(petition, signature).and_return(mailer)
    perform_job
  end

  it "doesn't run unless it's the latest request" do
    mailer.should_not_receive(:notify_signer_of_threshold_response)
    job = EmailThresholdResponseJob.new(1, Time.now - 1000, model, mailer)
    job.stub(:logger => logger)
    job.perform
  end

  it "marks the signature with the last emailing time" do
    signature.should_receive(:update_attribute).with(:last_emailed_at, email_requested_at)
    perform_job
  end

  context "email sending fails" do
    before do
      mailer.stub(:notify_signer_of_threshold_response).and_raise(Errno::ECONNREFUSED)
    end

    it "should catch the error" do
      lambda { perform_job }.should_not raise_error(Errno::ECONNREFUSED)
    end

    it "skips that signature and moves on" do
      signature.should_not_receive(:update_attribute).with(:last_emailed_at)
      perform_job
    end

    context "with more emails to process" do
      before do
        petition.stub_chain(:need_emailing, :count => 1)
      end

      it "raises an error at the end of the run to force a retry" do
        lambda { perform_job }.should raise_error(PleaseRetryEmailJob)
      end

      it "does not log the exception as an error" do
        petition.stub_chain(:need_emailing, :count => 1)
        logger.should_not_receive(:error)
        lambda { perform_job }.should raise_error
      end
    end
  end

  context "email fails with an SMTPError" do
    before do
      mailer.stub(:notify_signer_of_threshold_response).and_raise(Net::SMTPFatalError)
    end

    it "should catch the error" do
      lambda { perform_job }.should_not raise_error(Net::SMTPError)
    end

    it "skips that signature and moves on" do
      signature.should_not_receive(:update_attribute).with(:last_emailed_at)
      perform_job
    end
  end

  context "update attribute fails" do
    it "lets other exceptions through" do
      signature.stub(:update_attribute).and_raise(Exception)
      lambda { perform_job }.should raise_error
    end
  end
end
