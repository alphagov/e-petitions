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

    it "doesn't notify NewRelic" do
      expect(NewRelic::Agent).not_to receive(:notice_error)

      perform_enqueued_jobs {
        described_class.perform_later
      }
    end
  end

  context "when there are petitions with invalid signature counts" do
    let!(:petition) { FactoryGirl.create(:open_petition, signature_count: 100) }

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

    it "notifies NewRelic" do
      expect(NewRelic::Agent).to receive(:notice_error).with <<-MSG.strip
        There was 1 petition with id: #{petition.id} that had an invalid signature count
      MSG

      perform_enqueued_jobs {
        described_class.perform_later
      }
    end
  end
end
