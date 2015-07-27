require 'rails_helper'

RSpec.describe EmailPetitionSignatoriesJob, type: :job do
  describe '.run_later_tonight' do
    let(:petition) { FactoryGirl.create(:open_petition) }
    let(:requested_at) { Time.current }

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
