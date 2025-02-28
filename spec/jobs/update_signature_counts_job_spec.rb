require 'rails_helper'

RSpec.describe UpdateSignatureCountsJob, type: :job do
  let(:interval) { 30 }
  let(:current_time) { Time.current.change(usec: 0) }
  let(:scheduled_time) { interval.seconds.since(current_time) }
  let(:previous_count_updated_at) { current_time - (2 * interval).seconds }
  let(:current_count_updated_at) { current_time - interval.seconds }

  before do
    Site.signature_count_updated_at!(previous_count_updated_at)
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
      }.to(current_count_updated_at)
    end

    it "reschedules another job" do
      expect {
        described_class.perform_now(current_time.iso8601)
      }.to have_enqueued_job(described_class).on_queue("counter").at(scheduled_time)
    end

    describe "updating" do
      let(:location) { FactoryBot.create(:location, code: "AA", name: "Country 1") }
      let(:country_journal) { CountryPetitionJournal.for(petition, location.code) }
      let(:constituency_journal) { ConstituencyPetitionJournal.for(petition, "9999") }

      before do
        # Rewind the petition to the previous count state
        petition.update_signature_count!(previous_count_updated_at)
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

      context "when the count has never been updated before" do
        let(:petition) { FactoryBot.create(:pending_petition) }

        before do
          Site.signature_count_updated_at!(nil)
        end

        context "and there are no validated signatures" do
          it "updates Site#signature_count_updated_at" do
            expect {
              described_class.perform_now(current_time.iso8601)
            }.to change {
              Site.signature_count_updated_at
            }.from(nil).to(current_count_updated_at)
          end
        end

        context "and there are validated signatures" do
          let(:petition) { FactoryBot.create(:open_petition) }
          let(:attributes) { { petition: petition, location_code: location.code, constituency_id: "9999" } }
          let(:signatures) { FactoryBot.create_list(:pending_signature, 5, attributes) }

          before do
            signatures.each do |signature|
              signature.validate!(current_time - 45.seconds)
            end
          end

          it "updates Site#signature_count_updated_at" do
            expect {
              described_class.perform_now(current_time.iso8601)
            }.to change {
              Site.signature_count_updated_at
            }.to(current_count_updated_at)
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
      end

      shared_examples_for "it notifies Appsignal and doesn't retry" do
        before do
          allow(Appsignal).to receive(:send_exception)
          described_class.perform_now(current_time.iso8601)
        end

        it "notifies Appsignal" do
          expect(Appsignal).to have_received(:send_exception).with(an_instance_of(exception_class))
        end

        it "doesn't reschedule a job" do
          expect(described_class).not_to have_been_enqueued
        end
      end

      context "when a connection error occurs" do
        let(:petition) { FactoryBot.create(:open_petition) }
        let(:exception_class) { PG::ConnectionBad }

        before do
          expect(Signature).to receive(:petition_ids_signed_since).and_raise(exception_class)
        end

        include_examples "it notifies Appsignal and doesn't retry"
      end

      context "when an advisory lock error occurs" do
        let(:petition) { FactoryBot.create(:open_petition) }
        let(:exception_class) { SessionAdvisoryLock::LockFailedError }
        let(:connection) { ActiveRecord::Base.connection }
        let(:query) { a_string_matching(/pg_try_advisory_lock/) }

        before do
          expect(connection).to receive(:select_value).with(query).and_return(false)
        end

        include_examples "it notifies Appsignal and doesn't retry"
      end

      context "when multiple jobs are enqueued" do
        let(:petition) { FactoryBot.create(:open_petition) }
        let(:worker) { Delayed::Worker.new }

        around do |example|
          without_test_adapter { example.run }
        end

        before do
          described_class.perform_later((current_time - 15.seconds).iso8601)
          described_class.perform_later((current_time - 10.seconds).iso8601)
        end

        it "ensures that there is only one job running" do
          expect {
            worker.work_off
          }.to change(Delayed::Job, :count).from(2).to(1)
        end
      end
    end
  end
end
