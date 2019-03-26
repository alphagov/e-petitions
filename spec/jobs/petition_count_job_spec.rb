require 'rails_helper'

RSpec.describe PetitionCountJob, type: :job do
  context "when there are no petitions with invalid signature counts" do
    let!(:petition) { FactoryBot.create(:open_petition) }

    it "doesn't update the signature count" do
      expect{
        described_class.perform_now
      }.not_to change { petition.reload.signature_count }
    end

    it "doesn't change the updated_at timestamp" do
      expect{
        described_class.perform_now
      }.not_to change { petition.reload.updated_at }
    end

    it "doesn't notify AppSignal" do
      expect(Appsignal).not_to receive(:send_exception)

      described_class.perform_now
    end
  end

  context "when there are petitions with invalid signature counts" do
    let(:exception_class) { PetitionCountJob::InvalidSignatureCounts }

    let!(:petition) do
      FactoryBot.create(:open_petition,
        created_at: 2.days.ago,
        last_signed_at: Time.current,
        signature_count: 100
      )
    end

    context "and signature count updating is enabled" do
      before do
        Site.enable_signature_counts!
      end

      it "disables the signature count updating" do
        expect {
          described_class.perform_now
        }.to change { Site.update_signature_counts }.from(true).to(false)
      end

      it "reschedules the job" do
        expect {
          described_class.perform_now
        }.to have_enqueued_job(PetitionCountJob)
      end
    end

    context "and signature count updating is disabled" do
      before do
        Site.disable_signature_counts!
      end

      it "updates the signature count" do
        expect {
          described_class.perform_now
        }.to change { petition.reload.signature_count }.from(100).to(1)
      end

      it "updates the updated_at timestamp" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later
          }
        }.to change { petition.reload.updated_at }.to(be_within(1.second).of(Time.current))
      end

      it "notifies AppSignal" do
        expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))

        perform_enqueued_jobs {
          described_class.perform_later
        }
      end

      it "enables the signature count updating" do
        expect {
          described_class.perform_now
        }.to change { Site.update_signature_counts }.from(false).to(true)
      end

      it "schedules the update signature count job" do
        expect {
          described_class.perform_now
        }.to have_enqueued_job(UpdateSignatureCountsJob)
      end
    end
  end
end
