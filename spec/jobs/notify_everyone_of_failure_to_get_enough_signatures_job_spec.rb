require 'rails_helper'

RSpec.describe NotifyEveryoneOfFailureToGetEnoughSignaturesJob, type: :job do
  let(:petition) { FactoryBot.create(:pending_petition, sponsor_count: 0) }
  let(:creator) { petition.creator }
  let(:validated_sponsor) { FactoryBot.create(:sponsor, :validated, petition: petition) }
  let(:pending_sponsor) { FactoryBot.create(:sponsor, :pending, petition: petition) }

  context "when the petition fails to get enough signatures" do
    before do
      petition.reject(code: "insufficient")
    end

    it "notifies the creator" do
      expect(PetitionMailer).to receive(:notify_creator_that_petition_was_rejected).with(creator).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(petition)
      end
    end

    it "notifies the validated sponsors" do
      expect(PetitionMailer).to receive(:notify_sponsor_that_petition_was_rejected).with(validated_sponsor).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(petition)
      end
    end

    it "doesn't notify the pending sponsors" do
      expect(PetitionMailer).not_to receive(:notify_sponsor_that_petition_was_rejected).with(pending_sponsor)

      perform_enqueued_jobs do
        described_class.perform_later(petition)
      end
    end
  end
end
