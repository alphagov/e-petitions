require 'rails_helper'

RSpec.describe ExtendPetitionDeadlinesJob, type: :job do
  let!(:petition) { FactoryBot.create(:open_petition) }

  context "when signature collection is not disabled" do
    before do
      expect(Site).to receive(:signature_collection_disabled?).and_return(false)
    end

    it "doesn't increment the deadline_extension attribute" do
      expect {
        described_class.perform_now
      }.not_to change {
        petition.reload.deadline_extension
      }
    end
  end

  context "when signature collection is disabled" do
    before do
      expect(Site).to receive(:signature_collection_disabled?).and_return(true)
    end

    it "increments the deadline_extension attribute by 1 day" do
      expect {
        described_class.perform_now
      }.to change {
        petition.reload.deadline_extension
      }.from(0.days).to(1.day)
    end
  end
end
