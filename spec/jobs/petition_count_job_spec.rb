require 'rails_helper'

RSpec.describe PetitionCountJob, type: :job do
  context "when there are no petitions with invalid signature counts" do
    let!(:petition) { FactoryGirl.create(:open_petition) }

    it "doesn't update the signature count" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.not_to change{ petition.reload.signature_count }
    end

    it "doesn't change the updated_at timestamp" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.not_to change{ petition.reload.updated_at }
    end

    it "doesn't notify AppSignal" do
      expect(Appsignal).not_to receive(:send_exception)

      perform_enqueued_jobs {
        described_class.perform_later
      }
    end
  end

  context "when there are petitions with invalid signature counts" do
    let!(:petition) { FactoryGirl.create(:open_petition, signature_count: 100) }
    let(:exception_class) { PetitionCountJob::InvalidSignatureCounts }

    it "updates the signature count" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.signature_count }.from(100).to(1)
    end

    it "updates the updated_at timestamp" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.updated_at }.to(be_within(1.second).of(Time.current))
    end

    it "notifies AppSignal" do
      expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))

      perform_enqueued_jobs {
        described_class.perform_later
      }
    end
  end
end
