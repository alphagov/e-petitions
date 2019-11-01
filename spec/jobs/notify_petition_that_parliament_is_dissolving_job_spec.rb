require 'rails_helper'

RSpec.describe NotifyPetitionThatParliamentIsDissolvingJob, type: :job do
  let!(:petition) { FactoryBot.create(:open_petition, creator_email: "alice@example.com") }

  before do
    FactoryBot.create(:validated_signature, email: "bob@example.com", notify_by_email: true)
    FactoryBot.create(:validated_signature, email: "charlie@example.com", notify_by_email: false)
  end

  context "when notification records don't exist" do
    before do
      DissolutionNotification.reset!
    end

    it "enqueues a job for Alice" do
      expect {
        described_class.perform_now(petition)
      }.to have_enqueued_job(
        DeliverDissolutionNotificationJob
      ).with(
        DissolutionNotification.find_by(id: "6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6")
      ).on_queue("low_priority")
    end

    it "enqueues a job for Bob" do
      expect {
        described_class.perform_now(petition)
      }.to have_enqueued_job(
        DeliverDissolutionNotificationJob
      ).with(
        DissolutionNotification.find_by(id: "b1c51b78-4720-546f-b8b4-b7d925d6b1b9")
      ).on_queue("low_priority")
    end

    it "doesn't create a dissolution notification for Charlie" do
      expect {
        described_class.perform_now(petition)
      }.not_to change {
        DissolutionNotification.find_by(id: "d85a62b0-efb6-51a2-9087-a10881e6728e")
      }.from(nil)
    end
  end

  context "when notification records already exist" do
    before do
      DissolutionNotification.create!(id: "6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6")
      DissolutionNotification.create!(id: "b1c51b78-4720-546f-b8b4-b7d925d6b1b9")
      DissolutionNotification.create!(id: "d85a62b0-efb6-51a2-9087-a10881e6728e")
    end

    it "doesn't enqueue a job for Alice" do
      expect {
        described_class.perform_now(petition)
      }.not_to have_enqueued_job(
        DeliverDissolutionNotificationJob
      ).with(
        DissolutionNotification.find_by(id: "6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6")
      )
    end

    it "doesn't enqueue a job for Bob" do
      expect {
        described_class.perform_now(petition)
      }.not_to have_enqueued_job(
        DeliverDissolutionNotificationJob
      ).with(
        DissolutionNotification.find_by(id: "b1c51b78-4720-546f-b8b4-b7d925d6b1b9")
      )
    end

    it "doesn't enqueue a job for Charlie" do
      expect {
        described_class.perform_now(petition)
      }.not_to have_enqueued_job(
        DeliverDissolutionNotificationJob
      ).with(
        DissolutionNotification.find_by(id: "d85a62b0-efb6-51a2-9087-a10881e6728e")
      )
    end
  end
end
