require 'rails_helper'

RSpec.describe NotifyEveryoneOfModerationDecisionJob, type: :job do
  let(:petition) { FactoryBot.create(:validated_petition, sponsor_count: 0) }
  let(:creator) { petition.creator }
  let(:validated_sponsor) { FactoryBot.create(:sponsor, :validated, petition: petition) }
  let(:pending_sponsor) { FactoryBot.create(:sponsor, :pending, petition: petition) }

  context "when the petition is published" do
    before do
      petition.publish!
    end

    it "notifies the creator" do
      expect(PetitionMailer).to receive(:notify_creator_that_petition_is_published).with(creator).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(petition)
      end
    end

    it "notifies the validated sponsors" do
      expect(PetitionMailer).to receive(:notify_sponsor_that_petition_is_published).with(validated_sponsor).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(petition)
      end
    end

    it "doesn't notify the pending sponsors" do
      expect(PetitionMailer).not_to receive(:notify_sponsor_that_petition_is_published).with(pending_sponsor)

      perform_enqueued_jobs do
        described_class.perform_later(petition)
      end
    end
  end

  context "when the petition is rejected" do
    before do
      petition.reject!(code: "duplicate")
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

  context "when the petition is hidden" do
    before do
      petition.reject!(code: "offensive")
    end

    it "notifies the creator" do
      expect(PetitionMailer).to receive(:notify_creator_that_petition_was_hidden).with(creator).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(petition)
      end
    end

    it "notifies the validated sponsors" do
      expect(PetitionMailer).to receive(:notify_sponsor_that_petition_was_hidden).with(validated_sponsor).and_call_original

      perform_enqueued_jobs do
        described_class.perform_later(petition)
      end
    end

    it "doesn't notify the pending sponsors" do
      expect(PetitionMailer).not_to receive(:notify_sponsor_that_petition_was_hidden).with(pending_sponsor)

      perform_enqueued_jobs do
        described_class.perform_later(petition)
      end
    end
  end
end
