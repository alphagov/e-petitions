require 'rails_helper'

RSpec.describe UpdateSignatureCountsJob, type: :job do
  let(:current_time) { Time.current.change(usec: 0) }
  let(:interval) { 30 }
  let(:scheduled_time) { interval.seconds.since(current_time) }

  before do
    Site.signature_count_updated_at!(current_time - 60.seconds)
    allow(Site).to receive(:signature_count_interval).and_return(interval)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("INLINE_UPDATES").and_return("false")
  end

  context "when signature count updating is disabled" do
    before do
      allow(Site).to receive(:update_signature_counts).and_return(false)
    end

    it "doesn't update Site#signature_count_updated_at" do
      expect {
        described_class.perform_now(current_time.iso8601)
      }.not_to change {
        Site.signature_count_updated_at
      }
    end

    it "doesn't reschedule another job" do
      expect {
        described_class.perform_now(current_time.iso8601)
      }.not_to have_enqueued_job(described_class)
    end
  end

  context "when signature count updating is enabled" do
    before do
      allow(Site).to receive(:update_signature_counts).and_return(true)
    end

    it "updates Site#signature_count_updated_at" do
      expect {
        described_class.perform_now(current_time.iso8601)
      }.to change {
        Site.signature_count_updated_at
      }.to(current_time - 30.seconds)
    end

    it "reschedules another job" do
      expect {
        described_class.perform_now(current_time.iso8601)
      }.to have_enqueued_job(described_class).on_queue("highest_priority").at(scheduled_time)
    end

    describe "updating" do
      let(:location) { FactoryBot.create(:location, code: "AA", name: "Country 1") }
      let(:country_journal) { CountryPetitionJournal.for(petition, location.code) }
      let(:constituency_journal) { ConstituencyPetitionJournal.for(petition, "9999") }

      before do
        # FIXME: reset the signature count to ensure it's valid because
        # the factories don't leave the petition in a consistent state.
        petition.update_signature_count!(current_time - 60.seconds)
      end

      context "with an open petition" do
        let(:petition) { FactoryBot.create(:open_petition) }
        let(:attributes) { { petition: petition, location_code: location.code, constituency_id: "9999" } }
        let(:signatures) { FactoryBot.create_list(:pending_signature, 5, attributes) }

        before do
          signatures.each do |signature|
            signature.validate!(current_time - 45.seconds)
          end
        end

        it "updates the signature count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.to change {
            petition.reload.signature_count
          }.by(5)
        end

        it "updates the country journal signature_count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.to change {
            country_journal.reload.signature_count
          }.by(5)
        end

        it "updates the constituency journal signature_count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.to change {
            constituency_journal.reload.signature_count
          }.by(5)
        end
      end

      context "with a pending petition" do
        let(:petition) { FactoryBot.create(:pending_petition) }
        let(:attributes) { { petition: petition, location_code: location.code, constituency_id: "9999" } }
        let(:signatures) { FactoryBot.create_list(:pending_signature, 5, attributes) }

        before do
          signatures.each do |signature|
            signature.validate!(current_time - 45.seconds)
          end

          # A new petition won't have been counted yet so we need
          # to reset last_signed_at back to nil after the FIXME above.
          petition.update_columns(last_signed_at: nil)
          country_journal.update_columns(last_signed_at: nil)
          constituency_journal.update_columns(last_signed_at: nil)
        end

        it "updates the signature count" do
          # This changes by 6 because the creator is validated by the first signature
          expect {
            described_class.perform_now(current_time.iso8601)
          }.to change {
            petition.reload.signature_count
          }.by(6)
        end

        it "updates the country journal signature_count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.to change {
            country_journal.reload.signature_count
          }.by(5)
        end

        it "updates the constituency journal signature_count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.to change {
            constituency_journal.reload.signature_count
          }.by(5)
        end
      end

      context "with a pending petition that's had its creator validated after the current time window" do
        let(:petition) { FactoryBot.create(:pending_petition, creator_attributes: { location_code: location.code, constituency_id: "9999" }) }

        before do
          # A new petition won't have been counted yet so we need
          # to reset last_signed_at back to nil after the FIXME above.
          petition.update_columns(last_signed_at: nil)

          # Ensure that the signature falls within the expected window
          travel_to (1.second.ago) do
            petition.validate_creator!
          end
        end

        it "doesn't update the siganture count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.not_to change {
            petition.reload.signature_count
          }.from(0)
        end

        it "doesn't update the country journal signature_count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.not_to change {
            country_journal.reload.signature_count
          }.from(0)
        end

        it "doesn't update the constituency journal signature_count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.not_to change {
            constituency_journal.reload.signature_count
          }.from(0)
        end

        context "and when the next time window occurs" do
          let(:next_time) { current_time + interval.seconds }

          it "updates the siganture count" do
            expect {
              described_class.perform_now(next_time.iso8601)
            }.to change {
              petition.reload.signature_count
            }.from(0).to(1)
          end

          it "updates the country journal signature_count" do
            expect {
              described_class.perform_now(next_time.iso8601)
            }.to change {
              country_journal.reload.signature_count
            }.from(0).to(1)
          end

          it "updates the constituency journal signature_count" do
            expect {
              described_class.perform_now(next_time.iso8601)
            }.to change {
              constituency_journal.reload.signature_count
            }.from(0).to(1)
          end
        end

        context "and when the next time window occurs after that" do
          let(:next_time) { current_time + interval.seconds }
          let(:third_time) { next_time + interval.seconds }

          before do
            described_class.perform_now(next_time.iso8601)
          end

          it "doesn't update the siganture count" do
            expect {
              described_class.perform_now(third_time.iso8601)
            }.not_to change {
              petition.reload.signature_count
            }.from(1)
          end

          it "doesn't update the constituency journal signature_count" do
            expect {
              described_class.perform_now(third_time.iso8601)
            }.not_to change {
              constituency_journal.reload.signature_count
            }.from(1)
          end

          it "doesn't update the country journal signature_count" do
            expect {
              described_class.perform_now(third_time.iso8601)
            }.not_to change {
              country_journal.reload.signature_count
            }.from(1)
          end
        end
      end

      context "with a validated petition" do
        let(:petition) { FactoryBot.create(:validated_petition) }
        let(:attributes) { { petition: petition, location_code: "AA", constituency_id: "9999" } }
        let(:signatures) { FactoryBot.create_list(:pending_signature, 5, attributes) }

        before do
          signatures.each do |signature|
            signature.validate!(current_time - 45.seconds)
          end
        end

        it "updates the signature count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.to change {
            petition.reload.signature_count
          }.by(5)
        end

        it "updates the country journal signature_count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.to change {
            country_journal.reload.signature_count
          }.by(5)
        end

        it "updates the constituency journal signature_count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.to change {
            constituency_journal.reload.signature_count
          }.by(5)
        end
      end

      context "with a petition that's having its count reset" do
        let(:petition) { FactoryBot.create(:open_petition, signature_count_reset_at: current_time) }
        let(:attributes) { { petition: petition, location_code: "AA", constituency_id: "9999" } }
        let(:signatures) { FactoryBot.create_list(:pending_signature, 5, attributes) }

        before do
          signatures.each do |signature|
            signature.validate!(current_time - 45.seconds)
          end
        end

        it "doesn't update the signature count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.not_to change {
            petition.reload.signature_count
          }
        end

        it "doesn't update the country journal signature_count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.not_to change {
            country_journal.reload.signature_count
          }
        end

        it "doesn't update the constituency journal signature_count" do
          expect {
            described_class.perform_now(current_time.iso8601)
          }.not_to change {
            constituency_journal.reload.signature_count
          }
        end
      end

      context "with a petition that's having its count reset for more than 5 minutes" do
        let(:petition) { FactoryBot.create(:open_petition, signature_count_reset_at: 10.minutes.ago) }
        let(:attributes) { { petition: petition, location_code: "AA", constituency_id: "9999" } }
        let(:signatures) { FactoryBot.create_list(:pending_signature, 5, attributes) }

        before do
          signatures.each do |signature|
            signature.validate!(current_time - 45.seconds)
          end

          allow(Appsignal).to receive(:send_exception)
        end

        it "notifies Appsignal" do
          described_class.perform_now(current_time.iso8601)
          expect(Appsignal).to have_received(:send_exception).with(an_instance_of(RuntimeError))
        end
      end
    end
  end
end
