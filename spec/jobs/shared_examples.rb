RSpec.shared_examples_for "job to enqueue signatory mailing jobs" do
  def do_work(requested_at = email_requested_at)
    @requested_at = requested_at.getutc.iso8601
    subject.perform(petition, requested_at)
  end

  context "when the petition has not been updated" do
    it "enqueues a job to send an email to each signatory" do
      do_work
      expect(enqueued_jobs.size).to eq(1)
    end

    it "the job is the correct type for the type of notification" do
      do_work
      job = enqueued_jobs.first
      expect(job[:job]).to eq(subject.email_delivery_job_class)
    end

    it "the job has the expected arguments" do
      do_work
      args = enqueued_jobs.first[:args].first

      expect(args["timestamp_name"]).to eq(subject.timestamp_name)
      expect(args["requested_at_as_string"]).to eq(@requested_at)
    end
  end

  context "when the petition has been updated" do
    before do
      petition.set_email_requested_at_for(subject.timestamp_name, to: Time.current + 5.minutes )
    end

    it "does not enqueue any jobs to send emails" do
      do_work
      expect(enqueued_jobs).to be_empty
    end
  end
end

RSpec.shared_examples_for "a job to send an signatory email" do
  def perform_job
    @requested_at_as_string = email_requested_at.getutc.iso8601
    subject.perform(
      signature: signature,
      timestamp_name: timestamp_name,
      petition: petition,
      requested_at_as_string: @requested_at_as_string,
      logger: logger
    )
  end

  let(:logger) { double("Logger").as_null_object }

  context "when the petition has not been updated" do
    it "uses the correct mailer to generate the email" do
      expect(subject).to receive(:create_email).and_call_original
      perform_job
    end

    it "delivers the rendered email supplied by #create_email" do
      rendered_email = double("Rendered email")
      expect(rendered_email).to receive(:deliver_now)
      allow(subject).to receive(:create_email).and_return rendered_email
      perform_job
    end

    it "does sends the email" do
      expect { perform_job }.to change(ActionMailer::Base.deliveries, :size).by(1)
    end

    it "records the email being sent" do
      expect { perform_job }.to change(EmailSentReceipt, :count).by(1)
    end

    context "an email has already been sent for the petition to this signatory" do
      before do
        signature.set_email_sent_at_for timestamp_name, to: petition.get_email_requested_at_for(timestamp_name)
      end

      it "does not send any email" do
        expect { perform_job }.not_to change(ActionMailer::Base.deliveries, :size)
      end

      it "does not record any email being sent" do
        expect { perform_job }.not_to change(signature.email_sent_receipt.reload, :updated_at)
      end
    end

    context "email sending fails" do
      shared_examples_for 'catching errors during individual email sending' do
        before do
          allow(subject).to receive(:create_email).and_raise(exception_class)
        end

        it "captures the error and reraises it" do
          expect { perform_job }.to raise_error(exception_class)
        end

        it 'logs the email sending error as information' do
          expect(logger).to receive(:info).with(/#{Regexp.escape(exception_class.name)}/)
          suppress(exception_class) { perform_job }
        end

        it "does not mark the signature" do
          suppress(exception_class) { perform_job }
          signature.reload
          expect(signature.get_email_sent_at_for(timestamp_name)).not_to be_usec_precise_with email_requested_at
        end
      end

      context "with connection refused" do
        let(:exception_class) { Errno::ECONNREFUSED }

        it_behaves_like 'catching errors during individual email sending'
      end

      context "with an SMTPError" do
        let(:exception_class) { Net::SMTPFatalError }

        it_behaves_like 'catching errors during individual email sending'
      end

      context 'with a timeout' do
        let(:exception_class) { Errno::ETIMEDOUT }

        it_behaves_like 'catching errors during individual email sending'
      end
    end
  end

  context "when the petition has been updated" do
    before do
      petition.set_email_requested_at_for(timestamp_name, to: Time.current + 5.minutes )
    end

    it "does not send any email" do
      expect { perform_job }.not_to change(ActionMailer::Base.deliveries, :size)
    end

    it "does not record any email being sent" do
      expect { perform_job }.not_to change(EmailSentReceipt, :count)
    end
  end
end
