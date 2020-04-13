RSpec.shared_examples_for "job to enqueue signatory mailing jobs" do
  let(:requested_at) { Time.current.change(usec: 0) }
  let(:requested_at_as_string) { requested_at.getutc.iso8601(6) }

  def do_work
    subject.perform(petition: petition, requested_at: requested_at_as_string)
  end

  describe '.run_later_tonight' do
    let(:petition_gid) { { "_aj_globalid" => petition.to_global_id.to_s } }

    let(:queue_size) { enqueued_jobs.size }
    let(:enqueued_job) { enqueued_jobs.first }
    let(:job_class) { enqueued_job[:job] }
    let(:queued_at) { enqueued_job[:at] }
    let(:job_arguments) { enqueued_job[:args][0] }

    let(:window_duration) { 240.minutes + 60.seconds }
    let(:window_start) { requested_at.end_of_day.to_f }
    let(:window_end) { window_start + window_duration.to_f }
    let(:execution_window) { window_start..window_end }

    around do |example|
      travel_to requested_at do
        example.run
      end
    end

    before do
      described_class.run_later_tonight(**arguments)
    end

    it 'queues up a job' do
      expect(queue_size).to eq 1
      expect(job_class).to eq described_class
    end

    it 'sets the job to run between midnight and 4am tomorrow' do
      expect(queued_at).to be_in(execution_window)
    end

    it 'queues up the job to run with the petition and timestamp supplied as args' do
      expect(job_arguments['petition']).to eq petition_gid
      expect(job_arguments['requested_at']).to eq requested_at_as_string
    end
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
      expect(args["requested_at"]).to eq(requested_at_as_string)
    end
  end

  context "when the petition has been updated" do
    before do
      petition.set_email_requested_at_for(subject.timestamp_name, to: requested_at + 5.minutes )
    end

    it "does not enqueue any jobs to send emails" do
      do_work
      expect(enqueued_jobs).to be_empty
    end
  end
end

RSpec.shared_examples_for "a job to send an signatory email" do
  let(:job) { described_class.new(arguments) }

  context "when the petition has not been updated" do
    let(:mail_object) { double(:mail_object) }

    it "uses the correct notify job to generate the email" do
      expect(job).to receive(:create_email).and_call_original
      perform_enqueued_jobs { job.perform_now }
    end

    it "delivers the email returned by #create_email" do
      expect(job).to receive(:create_email).and_return(mail_object)
      expect(mail_object).to receive(:enqueue)
      perform_enqueued_jobs { job.perform_now }
    end

    it "does sends the email" do
      expect {
        perform_enqueued_jobs { job.perform_now }
      }.to change(ActionMailer::Base.deliveries, :size).by(1)
    end

    it "records the email being sent" do
      expect {
        perform_enqueued_jobs { job.perform_now }
      }.to change {
        signature.reload.get_email_sent_at_for(timestamp_name)
      }.from(nil).to(requested_at)
    end

    context "an email has already been sent for the petition to this signatory" do
      before do
        signature.set_email_sent_at_for timestamp_name, to: petition.get_email_requested_at_for(timestamp_name)
      end

      it "does not send any email" do
        expect {
          perform_enqueued_jobs { job.perform_now }
        }.not_to change(ActionMailer::Base.deliveries, :size)
      end

      it "does not record any email being sent" do
        expect {
          perform_enqueued_jobs { job.perform_now }
        }.not_to change {
          signature.reload.get_email_sent_at_for(timestamp_name)
        }
      end
    end
  end

  context "when the petition has been updated" do
    before do
      petition.set_email_requested_at_for(timestamp_name, to: Time.current + 5.minutes )
    end

    it "does not send any email" do
      expect {
        perform_enqueued_jobs { job.perform_now }
      }.not_to change(ActionMailer::Base.deliveries, :size)
    end

    it "does not record any email being sent" do
      expect {
        perform_enqueued_jobs { job.perform_now }
      }.not_to change {
        signature.reload.get_email_sent_at_for(timestamp_name)
      }
    end
  end
end
