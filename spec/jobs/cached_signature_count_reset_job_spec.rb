require 'rails_helper'

RSpec.describe CachedSignatureCountResetJob, type: :job do
  context "when there are no petitions updated in the last time period" do
    let!(:petition) { FactoryGirl.create(:open_petition, signature_count: 1000, updated_at: 10.minutes.ago) }

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
  end

  context "when there are are petitions updated in the last time period" do
    let!(:petition) { FactoryGirl.create(:open_petition, signature_count: 1000, updated_at: 2.minutes.ago) }

    before do
      Rails.cache.write("signature_counts/#{petition.id}", 2000, raw: true)
    end

    it "has an out of sync signature count" do
      expect(petition.signature_count).to eq(1000)
      expect(petition.cached_signature_count).to eq(2000)
    end

    it "updates the signature count" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.signature_count }.from(1000).to(2000)
    end

    it "doesn't change the updated_at timestamp" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.not_to change{ petition.reload.updated_at }
    end
  end
end
