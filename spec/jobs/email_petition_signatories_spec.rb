require 'net/smtp'
require 'rails_helper'

RSpec.describe EmailPetitionSignatories, type: :job do
  describe EmailPetitionSignatories::Job do
    context '.run_later_tonight' do
      let(:petition) { FactoryGirl.create(:open_petition) }
      let(:requested_at) { Time.current }
      before do
        ActiveJob::Base.queue_adapter.enqueued_jobs = []
        ActiveJob::Base.queue_adapter.performed_jobs = []
      end

      def global_id_job_arg_for(object)
        { "_aj_globalid" => object.to_global_id.to_s }
      end
      def timestamp_job_arg_for(timestamp)
        timestamp.getutc.iso8601
      end

      it 'queues up a job' do
        described_class.run_later_tonight(petition, requested_at)
        expect(enqueued_jobs.size).to eq 1
        expect(enqueued_jobs.first[:job]).to eq described_class
      end

      it 'sets the job to run between midnight and 4am tomorrow' do
        described_class.run_later_tonight(petition, requested_at)
        queued_at = enqueued_jobs.first[:at]
        expect(queued_at).to satisfy { |at| at >= (1.day.from_now.midnight.to_i) }
        expect(queued_at).to satisfy { |at| at <= (1.day.from_now.midnight + 4.hours).to_i }
      end

      it 'queues up the job to run with the petition and timestamp supplied as args' do
        described_class.run_later_tonight(petition, requested_at)
        queued_args = enqueued_jobs.first[:args]
        expect(queued_args[0]).to eq global_id_job_arg_for(petition)
        expect(queued_args[1]).to eq timestamp_job_arg_for(requested_at)
      end

      it 'adds any extra params provided as job args after the petition and timestamp' do
        described_class.run_later_tonight(petition, requested_at, 'cheese', 1, petition.creator_signature)
        queued_args = enqueued_jobs.first[:args]
        expect(queued_args[2]).to eq 'cheese'
        expect(queued_args[3]).to eq 1
        expect(queued_args[4]).to eq global_id_job_arg_for(petition.creator_signature)
      end
    end
  end

  describe EmailPetitionSignatories::Worker do
    let(:email_requested_at) { Time.current }
    let(:petition) { FactoryGirl.create(:open_petition) }
    let!(:signature) { FactoryGirl.create(:validated_signature, :petition => petition) }

    let(:timestamp_name) { 'government_response' }
    let(:job) { double(timestamp_name: timestamp_name).as_null_object }
    let(:logger) { double.as_null_object }
    let(:email) { double.as_null_object }

    before { petition.set_email_requested_at_for(timestamp_name, to: email_requested_at) }

    def do_work(requested_at = email_requested_at)
      requested_at = requested_at.getutc.iso8601
      described_class.new(job, petition, requested_at, logger).do_work!
    end

    it "asks the job to send an email to each signatory of a petition" do
      expect(job).to receive(:create_email).with(petition, signature).and_return email
      do_work
    end

    it "doesn't run unless it's the latest request according to the jobs timestamp name" do
      expect(job).not_to receive(:create_email)
      requested_at = email_requested_at - 1000
      do_work(requested_at)
    end

    it "marks the signature using the timestamp name and the time the job was requested " do
      do_work
      signature.reload
      expect(signature.get_email_sent_at_for(timestamp_name)).to be_usec_precise_with email_requested_at
    end

    context "email sending fails" do
      shared_examples_for 'catching errors during individual email sending' do
        before do
          allow(job).to receive(:create_email).and_return email
          allow(job).to receive(:create_email).with(petition, signature).and_raise(exception_class)
        end

        it "captures the error and raises a retry error" do
          expect { do_work }.to raise_error(EmailPetitionSignatories::PleaseRetry)
        end

        it 'logs the email sending error as information' do
          expect(logger).to receive(:info).with(/#{Regexp.escape(exception_class.name)}/)
          suppress(EmailPetitionSignatories::PleaseRetry) { do_work }
        end

        it "does not mark the signature" do
          suppress(EmailPetitionSignatories::PleaseRetry) { do_work }
          signature.reload
          expect(signature.get_email_sent_at_for(timestamp_name)).not_to be_usec_precise_with email_requested_at
        end

        it 'continues to process other signatures after the one that errored' do
          other_signature = FactoryGirl.create(:validated_signature, :petition => petition)
          suppress(EmailPetitionSignatories::PleaseRetry) { do_work }
          other_signature.reload
          expect(other_signature.get_email_sent_at_for(timestamp_name)).to be_usec_precise_with email_requested_at
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

      context "for some other reason" do
        before do
          allow(job).to receive(:create_email).and_return email
          allow(job).to receive(:create_email).with(petition, signature).and_raise(ActiveRecord::RecordNotSaved, 'uh oh!')
        end

        it "raises the error" do
          expect { do_work }.to raise_error(ActiveRecord::RecordNotSaved)
        end

        it "does not mark the signature" do
          suppress(ActiveRecord::RecordNotSaved) { do_work }
          signature.reload
          expect(signature.get_email_sent_at_for(timestamp_name)).not_to be_usec_precise_with email_requested_at
        end

        it 'does not process other signatures after the one that errored' do
          other_signature = FactoryGirl.create(:validated_signature, :petition => petition)
          suppress(ActiveRecord::RecordNotSaved) { do_work }
          other_signature.reload
          expect(other_signature.get_email_sent_at_for(timestamp_name)).not_to be_usec_precise_with email_requested_at
        end
      end
    end
  end
end
