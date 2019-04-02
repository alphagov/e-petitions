require 'rails_helper'

RSpec.describe TrendingDomainsByPetitionJob, type: :job do
  let(:rate_limit) { double(RateLimit) }
  let(:current_time) { Time.utc(2019, 3, 31, 16, 0, 0) }
  let(:petition) { FactoryBot.create(:open_petition) }

  before do
    allow(RateLimit).to receive(:first_or_create!).and_return(rate_limit)
    allow(rate_limit).to receive(:threshold_for_logging_trending_items).and_return(1)
    allow(rate_limit).to receive(:threshold_for_notifying_trending_items).and_return(2)
    allow(rate_limit).to receive(:ignore_domain?).and_return(false)

    FactoryBot.create(:validated_signature, petition: petition, email: "bob@public.com", validated_at: "2019-03-31T15:30:00Z")
    FactoryBot.create(:validated_signature, petition: petition, email: "alice@example.com", validated_at: "2019-03-31T15:35:00Z")
    FactoryBot.create(:validated_signature, petition: petition, email: "bob@example.com", validated_at: "2019-03-31T15:40:00Z")
  end

  context "when trending item logging is disabled" do
    before do
      allow(rate_limit).to receive(:enable_logging_of_trending_items?).and_return(false)
    end

    it "doesn't create any trending domain entries" do
      expect {
        described_class.perform_now(current_time)
      }.not_to change {
        TrendingDomain.count
      }
    end
  end

  context "when trending item logging is enabled" do
    before do
      allow(rate_limit).to receive(:enable_logging_of_trending_items?).and_return(true)
    end

    it "creates trending domain entries" do
      expect {
        described_class.perform_now(current_time)
      }.to change {
        TrendingDomain.count
      }.by(2)
    end

    it "enqueues a NotifyTrendingDomainJob for ip addresses that are above the threshold" do
      expect {
        described_class.perform_now(current_time)
      }.to have_enqueued_job(NotifyTrendingDomainJob)
    end

    context "and the domain is ignored" do
      let(:ignored_domains) { a_string_matching(/\A(?:example.com|public.com)\z/) }

      before do
        allow(rate_limit).to receive(:ignore_domain?).with(ignored_domains).and_return(true)
      end

      it "doesn't create any trending domain entries" do
        expect {
          described_class.perform_now(current_time)
        }.not_to change {
          TrendingDomain.count
        }
      end
    end
  end
end
