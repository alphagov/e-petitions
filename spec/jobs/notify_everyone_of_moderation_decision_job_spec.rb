require 'rails_helper'

RSpec.describe NotifyEveryoneOfModerationDecisionJob, type: :job do
  let!(:petition) { FactoryBot.create(:pending_petition, :translated, sponsor_count: 0) }
  let!(:validated_sponsor) { FactoryBot.create(:sponsor, :validated, petition: petition) }
  let!(:pending_sponsor) { FactoryBot.create(:sponsor, :pending, petition: petition) }

  let(:creator) { petition.creator }

  context "when the petition is published" do
    before do
      petition.publish
    end

    it "notifies the creator" do
      expect {
        described_class.perform_now(petition)
      }.to have_enqueued_job(
        NotifyCreatorThatPetitionIsPublishedEmailJob
      ).with(creator).on_queue("high_priority")
    end

    it "notifies the validated sponsors" do
      expect {
        described_class.perform_now(petition)
      }.to have_enqueued_job(
        NotifySponsorThatPetitionIsPublishedEmailJob
      ).with(validated_sponsor).on_queue("high_priority")
    end

    it "doesn't notify the pending sponsors" do
      expect {
        described_class.perform_now(petition)
      }.not_to have_enqueued_job(
        NotifySponsorThatPetitionIsPublishedEmailJob
      ).with(pending_sponsor).on_queue("high_priority")
    end
  end

  context "when the petition is rejected" do
    let(:rejection) { petition.rejection }

    before do
      petition.reject(code: "duplicate")
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

  context "when the petition is hidden" do
    let(:rejection) { petition.rejection }

    before do
      petition.reject(code: "offensive")
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
