require "rails_helper"

RSpec.describe EmailPrivacyPolicyUpdatesJob, type: :job do
  let(:time) { 1.year.ago }
  let(:subject) { described_class.perform_now(time: time) }

  Petition::MODERATED_STATES.each do |state|
    context "#{state} petition" do
      context "petition created after given time" do
        let!(:petition) do
          FactoryBot.create("#{state}_petition", created_at: time + 1.day)
        end

        it "enqueues job" do
          expect { subject }.to change { enqueued_jobs.count }.by(1)
        end
      end

      context "petition created at given time" do
        let!(:petition) do
          FactoryBot.create("#{state}_petition", created_at: time)
        end

        it "enqueues job" do
          expect { subject }.to change { enqueued_jobs.count }.by(1)
        end
      end

      context "petition created before given time" do
        let!(:petition) do
          FactoryBot.create("#{state}_petition", created_at: time - 1.day)
        end

        it "does not enqueue job" do
          expect { subject }.not_to change { enqueued_jobs.count }
        end
      end
    end
  end

  (Petition::STATES - Petition::MODERATED_STATES).each do |state|
    context "#{state} petition" do
      context "petition created after given time" do
        let!(:petition) do
          FactoryBot.create("#{state}_petition", created_at: time + 1.day)
        end

        it "does not enqueue job" do
          expect { subject }.not_to change { enqueued_jobs.count }
        end
      end
    end
  end
end
