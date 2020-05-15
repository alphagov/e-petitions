require 'rails_helper'

RSpec.describe ReferOrRejectPetitionsJob, type: :job do
  let!(:petition) {
    FactoryBot.create(:closed_petition, referred: referred, open_at: open_at, closed_at: nil)
  }

  around do |example|
    travel_to(now)
    example.run
    travel_back
  end

  context "for a petition opened in the winter" do
    let(:open_at) { "2015-12-29T10:00:00Z" }

    context "when the closing date has just passed" do
      let(:now) { "2016-06-29T07:05:00Z".in_time_zone }

      context "and the petition reached the referral threshold" do
        let(:referred) { true }

        it "does not refer the petition" do
          expect{
            perform_enqueued_jobs {
              described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
            }
          }.not_to change {
            petition.reload.referred_at
          }.from(nil)
        end
      end

      context "and the petition did not reach the referral threshold" do
        let(:referred) { false }

        it "does not reject the petition" do
          expect{
            perform_enqueued_jobs {
              described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
            }
          }.not_to change {
            petition.reload.state
          }.from("closed")
        end
      end
    end

    context "when the closing date has passed yesterday" do
      let(:now) { "2016-06-30T07:05:00Z".in_time_zone }

      context "and the petition reached the referral threshold" do
        let(:referred) { true }

        it "refers the petition" do
          expect{
            perform_enqueued_jobs {
              described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
            }
          }.to change {
            petition.reload.referred_at
          }.from(nil).to(Date.tomorrow.beginning_of_day)
        end
      end

      context "and the petition did not reach the referral threshold" do
        let(:referred) { false }

        it "rejects the petition" do
          expect{
            perform_enqueued_jobs {
              described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
            }
          }.to change {
            petition.reload.state
          }.from("closed").to("rejected")
        end
      end
    end
  end

  context "for a petition opened in the summer" do
    let(:open_at) { "2016-06-29T10:00:00Z" }

    context "when the closing date has just passed" do
      let(:now) { "2016-12-29T07:05:00Z".in_time_zone }

      context "and the petition reached the referral threshold" do
        let(:referred) { true }

        it "does not refer the petition" do
          expect{
            perform_enqueued_jobs {
              described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
            }
          }.not_to change {
            petition.reload.referred_at
          }.from(nil)
        end
      end

      context "and the petition did not reach the referral threshold" do
        let(:referred) { false }

        it "does not reject the petition" do
          expect{
            perform_enqueued_jobs {
              described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
            }
          }.not_to change {
            petition.reload.state
          }.from("closed")
        end
      end
    end

    context "when the closing date has passed yesterday" do
      let(:now) { "2016-12-30T07:05:00Z".in_time_zone }

      context "and the petition reached the referral threshold" do
        let(:referred) { true }

        it "refers the petition" do
          expect{
            perform_enqueued_jobs {
              described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
            }
          }.to change {
            petition.reload.referred_at
          }.from(nil).to(Date.tomorrow.beginning_of_day)
        end
      end

      context "and the petition did not reach the referral threshold" do
        let(:referred) { false }

        it "rejects the petition" do
          expect{
            perform_enqueued_jobs {
              described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
            }
          }.to change {
            petition.reload.state
          }.from("closed").to("rejected")
        end
      end
    end
  end
end
