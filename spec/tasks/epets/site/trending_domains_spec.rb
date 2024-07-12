require 'rails_helper'

RSpec.describe "epets:site:trending_domains", type: :task do
  around do |example|
    freeze_time { example.run }
  end

  let(:parliament) { Parliament.instance }

  context "when parliament is open" do
    before do
      allow(parliament).to receive(:dissolution_at).and_return(nil)
    end

    it "enqueues the TrendingDomainsByPetitionJob" do
      expect {
        subject.invoke
      }.to have_enqueued_job(
        TrendingDomainsByPetitionJob
      ).on_queue(:default)
    end
  end

  context "when parliament has dissolved less than 48 hours ago" do
    before do
      allow(parliament).to receive(:dissolution_at).and_return(24.hours.ago)
    end

    it "enqueues the TrendingDomainsByPetitionJob" do
      expect {
        subject.invoke
      }.to have_enqueued_job(
        TrendingDomainsByPetitionJob
      ).on_queue(:default)
    end
  end

  context "when parliament has dissolved more than 48 hours ago" do
    before do
      allow(parliament).to receive(:dissolution_at).and_return(72.hours.ago)
    end

    it "doesn't enqueue the TrendingDomainsByPetitionJob" do
      expect {
        subject.invoke
      }.not_to have_enqueued_job(
        TrendingDomainsByPetitionJob
      )
    end
  end
end
