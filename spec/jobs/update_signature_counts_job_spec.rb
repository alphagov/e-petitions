require 'rails_helper'

RSpec.describe UpdateSignatureCountsJob, type: :job do
  let(:current_time) { Time.current }
  let(:interval) { 30 }
  let(:scheduled_time) { interval.seconds.since(current_time) }

  before do
    allow(Site).to receive(:signature_count_interval).and_return(interval)
  end

  context "when signature count updating is disabled" do
    before do
      allow(Site).to receive(:update_signature_counts).and_return(false)
    end

    it "doesn't update Site#signature_count_updated_at" do
      expect {
        described_class.perform_now(current_time)
      }.not_to change {
        Site.signature_count_updated_at
      }
    end

    it "doesn't reschedule another job" do
      expect {
        described_class.perform_now(current_time)
      }.not_to have_enqueued_job(described_class)
    end
  end

  context "when signature count updating is enabled" do
    before do
      allow(Site).to receive(:update_signature_counts).and_return(true)
    end

    it "updates Site#signature_count_updated_at" do
      expect {
        described_class.perform_now(current_time)
      }.to change {
        Site.signature_count_updated_at
      }.to(current_time)
    end

    it "reschedules another job" do
      expect {
        described_class.perform_now(current_time)
      }.to have_enqueued_job(described_class).on_queue("highest_priority").at(scheduled_time)
    end

    describe "updating" do
      let(:location) { FactoryBot.create(:location, code: "AA", name: "Country 1") }
      let(:country_journal) { CountryPetitionJournal.for(petition, location.code) }
      let(:constituency_journal) { ConstituencyPetitionJournal.for(petition, "9999") }

      before do
        # FIXME: reset the signature count to ensure it's valid because
        # the factories don't leave the petition in a consistent state.
        petition.update_signature_count!
      end

      context "with an open petition" do
        let(:petition) { FactoryBot.create(:open_petition) }

        before do
          5.times do
            FactoryBot.create(:validated_signature, petition: petition, location_code: "AA", constituency_id: "9999")
          end
        end

        it "updates the signature count" do
          expect {
            described_class.perform_now(current_time)
          }.to change {
            petition.reload.signature_count
          }.by(5)
        end

        it "updates the country journal signature_count" do
          expect {
            described_class.perform_now(current_time)
          }.to change {
            country_journal.reload.signature_count
          }.by(5)
        end

        it "updates the constituency journal signature_count" do
          expect {
            described_class.perform_now(current_time)
          }.to change {
            constituency_journal.reload.signature_count
          }.by(5)
        end
      end

      context "with a pending petition" do
        let(:petition) { FactoryBot.create(:pending_petition) }

        before do
          5.times do
            FactoryBot.create(:validated_signature, petition: petition, location_code: "AA", constituency_id: "9999")
          end
        end

        it "updates the signature count" do
          expect {
            described_class.perform_now(current_time)
          }.to change {
            petition.reload.signature_count
          }.by(5)
        end

        it "updates the country journal signature_count" do
          expect {
            described_class.perform_now(current_time)
          }.to change {
            country_journal.reload.signature_count
          }.by(5)
        end

        it "updates the constituency journal signature_count" do
          expect {
            described_class.perform_now(current_time)
          }.to change {
            constituency_journal.reload.signature_count
          }.by(5)
        end
      end

      context "with a validated petition" do
        let(:petition) { FactoryBot.create(:validated_petition) }

        before do
          5.times do
            FactoryBot.create(:validated_signature, petition: petition, location_code: "AA", constituency_id: "9999")
          end
        end

        it "updates the signature count" do
          expect {
            described_class.perform_now(current_time)
          }.to change {
            petition.reload.signature_count
          }.by(5)
        end

        it "updates the country journal signature_count" do
          expect {
            described_class.perform_now(current_time)
          }.to change {
            country_journal.reload.signature_count
          }.by(5)
        end

        it "updates the constituency journal signature_count" do
          expect {
            described_class.perform_now(current_time)
          }.to change {
            constituency_journal.reload.signature_count
          }.by(5)
        end
      end
    end
  end
end
