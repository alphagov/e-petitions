require 'rails_helper'

RSpec.describe CachedPetitionValuesResetJob, type: :job do
  context "when there are no petitions updated in the last time period" do
    let!(:petition) { FactoryGirl.create(:petition, signature_count: 1000, updated_at: 30.minutes.ago) }

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

    it "doesn't change the last_signed_at timestamp" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.not_to change{ petition.reload.last_signed_at }
    end
  end

  context "when there are are petitions updated in the last time period" do
    let(:db_updated_at) { 5.minutes.ago.change(nsec: 0) }
    let(:cached_updated_at) { 1.minute.ago.change(nsec: 0) }
    let(:db_last_signed_at) { 6.minutes.ago.change(nsec: 0) }
    let(:cached_last_signed_at) { 2.minutes.ago.change(nsec: 0) }
    let(:petition) { FactoryGirl.create(:petition, signature_count: 1000, updated_at: db_updated_at, last_signed_at: db_last_signed_at) }

    before do
      travel_to Time.current
      Rails.cache.write("petition_updated_at_timestamps/#{petition.id}", cached_updated_at)
      Rails.cache.write("petition_last_signed_at_timestamps/#{petition.id}", cached_last_signed_at)
      Rails.cache.write("signature_counts/#{petition.id}", 2000, raw: true)
    end

    after do
      travel_back
    end

    it "has an out of sync signature count" do
      expect(petition.signature_count).to eq(1000)
      expect(petition.cached_signature_count).to eq(2000)
    end

    it "has an out of sync updated at timestamp" do
      expect(petition.updated_at).to eq(db_updated_at)
      expect(petition.cached_updated_at).to eq(cached_updated_at)
    end

    it "has an out of sync last signed at timestamp" do
      expect(petition.last_signed_at).to be_within(1.second).of(db_last_signed_at)
      expect(petition.cached_last_signed_at).to be_within(1.second).of(cached_last_signed_at)
    end

    it "updates the signature count" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.signature_count }.from(1000).to(2000)
    end

    it "updates the updated at timestamp" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.updated_at }.from(db_updated_at).to(cached_updated_at)
    end

    it "updates the last signed at timestamp" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.last_signed_at }.from(db_last_signed_at).to(cached_last_signed_at)
    end
  end

  context "when there are are petitions updated just outside last time period" do
    let(:db_updated_at) { 930.seconds.ago.change(nsec: 0) }
    let(:cached_updated_at) { 1.minute.ago.change(nsec: 0) }
    let(:db_last_signed_at) { 6.minutes.ago.change(nsec: 0) }
    let(:cached_last_signed_at) { 2.minutes.ago.change(nsec: 0) }
    let(:petition) { FactoryGirl.create(:petition, signature_count: 1000, updated_at: db_updated_at, last_signed_at: db_last_signed_at) }

    before do
      travel_to Time.current
      Rails.cache.write("petition_updated_at_timestamps/#{petition.id}", cached_updated_at)
      Rails.cache.write("petition_last_signed_at_timestamps/#{petition.id}", cached_last_signed_at)
      Rails.cache.write("signature_counts/#{petition.id}", 2000, raw: true)
    end

    after do
      travel_back
    end

    it "has an out of sync signature count" do
      expect(petition.signature_count).to eq(1000)
      expect(petition.cached_signature_count).to eq(2000)
    end

    it "has an out of sync updated at timestamp" do
      expect(petition.updated_at).to eq(db_updated_at)
      expect(petition.cached_updated_at).to eq(cached_updated_at)
    end

    it "has an out of sync last signed at timestamp" do
      expect(petition.last_signed_at).to eq(db_last_signed_at)
      expect(petition.cached_last_signed_at).to eq(cached_last_signed_at)
    end

    it "updates the signature count" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.signature_count }.from(1000).to(2000)
    end

    it "updates the updated at timestamp" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.updated_at }.from(db_updated_at).to(cached_updated_at)
    end

    it "updates the last signed at timestamp" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.last_signed_at }.from(db_last_signed_at).to(cached_last_signed_at)
    end
  end
end
