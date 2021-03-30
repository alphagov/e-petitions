require 'rails_helper'

RSpec.describe NotifyEveryoneOfFailureToGetEnoughSignaturesJob, type: :job do
  let(:petition) { FactoryBot.create(:open_petition, sponsor_count: 0) }
  let(:rejection) { petition.rejection }
  let(:creator) { petition.creator }
  let(:validated_sponsor) { FactoryBot.create(:sponsor, :validated, petition: petition) }
  let(:pending_sponsor) { FactoryBot.create(:sponsor, :pending, petition: petition) }

  context "when the petition fails to get enough signatures" do
    before do
      petition.reject!(code: "insufficient")
    end

    it "notifies the creator" do
      expect {
        described_class.perform_now(petition)
      }.to have_enqueued_job(
        NotifyCreatorThatPetitionWasRejectedEmailJob
      ).with(creator, rejection).on_queue("high_priority")
    end

    it "notifies the validated sponsors" do
      expect {
        described_class.perform_now(petition)
      }.to have_enqueued_job(
        NotifySponsorThatPetitionWasRejectedEmailJob
      ).with(validated_sponsor, rejection).on_queue("high_priority")
    end

    it "doesn't notify the pending sponsors" do
      expect {
        described_class.perform_now(petition)
      }.not_to have_enqueued_job(
        NotifySponsorThatPetitionWasRejectedEmailJob
      ).with(pending_sponsor, rejection).on_queue("high_priority")
    end
  end
end
