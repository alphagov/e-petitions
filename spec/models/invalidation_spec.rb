require 'rails_helper'

RSpec.describe Invalidation, type: :model do
  subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs") }

  it "has a valid factory" do
    expect(FactoryGirl.build(:invalidation, name: "Joe Bloggs")).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition) }
    it { is_expected.to have_many(:signatures) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index(:petition_id) }
  end

  describe "callbacks" do
    context "when an invalidation hasn't started" do
      let!(:invalidation) { FactoryGirl.create(:invalidation, name: "Joe Bloggs") }

      it "can be deleted" do
        expect(invalidation.destroy).to be_truthy
      end
    end

    context "when an invalidation has started" do
      let!(:invalidation) { FactoryGirl.create(:invalidation, :started, name: "Joe Bloggs") }

      it "can't be deleted" do
        expect(invalidation.destroy).to be_falsey
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:summary) }
    it { is_expected.to validate_length_of(:summary).is_at_most(255) }
    it { is_expected.to validate_length_of(:details).is_at_most(10000) }
    it { is_expected.to validate_numericality_of(:petition_id).only_integer.is_greater_than_or_equal_to(100000) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:postcode).is_at_most(255) }
    it { is_expected.to validate_length_of(:ip_address).is_at_most(20) }
    it { is_expected.to validate_length_of(:email).is_at_most(255) }
    it { is_expected.to validate_length_of(:constituency_id).is_at_most(30) }
    it { is_expected.to validate_length_of(:location_code).is_at_most(30) }

    it { is_expected.not_to allow_value("foo").for(:ip_address) }
    it { is_expected.to allow_value("123.123.123.123").for(:ip_address) }

    context "when there are no conditions" do
      subject { FactoryGirl.build(:invalidation) }

      before do
        subject.valid?
      end

      it "adds an error to :petition_id" do
        expect(subject.errors[:petition_id]).to include("Please select some conditions, otherwise all signatures will be invalidated")
      end
    end

    context "when a petition doesn't exist" do
      subject { FactoryGirl.build(:invalidation, petition_id: 123456) }

      before do
        subject.valid?
      end

      it "adds an error to :petition_id" do
        expect(subject.errors[:petition_id]).to include("Petition doesn't exist")
      end
    end

    context "when a constituency doesn't exist" do
      subject { FactoryGirl.build(:invalidation, constituency_id: "1234") }

      before do
        subject.valid?
      end

      it "adds an error to :constituency_id" do
        expect(subject.errors[:constituency_id]).to include("Constituency doesn't exist")
      end
    end

    context "when a constituency doesn't exist" do
      subject { FactoryGirl.build(:invalidation, constituency_id: "1234") }

      before do
        subject.valid?
      end

      it "adds an error to :constituency_id" do
        expect(subject.errors[:constituency_id]).to include("Constituency doesn't exist")
      end
    end

    context "when a location doesn't exist" do
      subject { FactoryGirl.build(:invalidation, location_code: "XX") }

      before do
        subject.valid?
      end

      it "adds an error to :location_code" do
        expect(subject.errors[:location_code]).to include("Location doesn't exist")
      end
    end

    context "when the date range is reversed" do
      subject { FactoryGirl.build(:invalidation, created_after: 2.weeks.ago, created_before: 3.weeks.ago) }

      before do
        subject.valid?
      end

      it "adds an error to :created_after" do
        expect(subject.errors[:created_after]).to include("Starting date is after the finishing date")
      end
    end
  end

  describe "class methods" do
    describe ".by_most_recent" do
      let!(:invalidation_1) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", created_at: 3.weeks.ago) }
      let!(:invalidation_2) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", created_at: 2.weeks.ago) }

      it "orders the invalidations by the created_at timestamp in descending order" do
        expect(described_class.by_most_recent.to_a).to eq([invalidation_2, invalidation_1])
      end
    end

    describe ".by_longest_running" do
      let!(:invalidation_1) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: 1.hour.ago) }
      let!(:invalidation_2) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: 2.hours.ago) }

      it "orders the invalidations by the started_at timestamp in ascending order" do
        expect(described_class.by_most_recent.to_a).to eq([invalidation_2, invalidation_1])
      end
    end

    describe ".cancelled" do
      let!(:invalidation_1) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", cancelled_at: nil) }
      let!(:invalidation_2) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", cancelled_at: 2.hours.ago) }

      it "scopes the query to invalidations with a cancelled_at timestamp" do
        expect(described_class.cancelled.to_a).to eq([invalidation_2])
      end
    end

    describe ".completed" do
      let!(:invalidation_1) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", completed_at: nil) }
      let!(:invalidation_2) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", completed_at: 2.hours.ago) }

      it "scopes the query to invalidations with a completed_at timestamp" do
        expect(described_class.completed.to_a).to eq([invalidation_2])
      end
    end

    describe ".enqueued" do
      let!(:invalidation_1) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", enqueued_at: nil) }
      let!(:invalidation_2) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", enqueued_at: 2.hours.ago) }
      let!(:invalidation_3) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", enqueued_at: 2.hours.ago, started_at: 1.hour.ago) }

      it "scopes the query to invalidations with a enqueued_at timestamp that have not started" do
        expect(described_class.enqueued.to_a).to eq([invalidation_2])
      end
    end

    describe ".not_completed" do
      let!(:invalidation_1) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", completed_at: nil) }
      let!(:invalidation_2) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", completed_at: 2.hours.ago) }

      it "scopes the query to invalidations without a completed_at timestamp" do
        expect(described_class.not_completed.to_a).to eq([invalidation_1])
      end
    end

    describe ".pending" do
      let!(:invalidation_1) { FactoryGirl.create(:invalidation, name: "Joe Bloggs") }
      let!(:invalidation_2) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", enqueued_at: 2.hours.ago) }
      let!(:invalidation_3) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: 2.hours.ago) }
      let!(:invalidation_4) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", cancelled_at: 2.hours.ago) }
      let!(:invalidation_5) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", completed_at: 2.hours.ago) }

      it "scopes the query to invalidations that have not been processed in anyway" do
        expect(described_class.pending.to_a).to eq([invalidation_1])
      end
    end

    describe ".running" do
      let!(:invalidation_1) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: 3.hours.ago, completed_at: nil) }
      let!(:invalidation_2) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: 3.hours.ago, completed_at: 2.hours.ago) }

      it "scopes the query to invalidations that have started, but not completed" do
        expect(described_class.running.to_a).to eq([invalidation_1])
      end
    end

    describe ".started" do
      let!(:invalidation_1) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: nil) }
      let!(:invalidation_2) { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: 2.hours.ago) }

      it "scopes the query to invalidations with a started_at timestamp" do
        expect(described_class.started.to_a).to eq([invalidation_2])
      end
    end
  end

  describe "instance methods" do
    describe "#cancelled?" do
      context "when cancelled_at is nil" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", cancelled_at: nil) }

        it "returns false" do
          expect(subject.cancelled?).to eq(false)
        end
      end

      context "when cancelled_at is set" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", cancelled_at: Time.current) }

        it "returns true" do
          expect(subject.cancelled?).to eq(true)
        end
      end
    end

    describe "#cancel!" do
      it "changes cancelled? from false to true" do
        expect {
          subject.cancel!
        }.to change {
          subject.cancelled?
        }.from(false).to(true)
      end

      it "it sets cancelled_at" do
        expect {
          subject.cancel!
        }.to change {
          subject.cancelled_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end

      context "when the invalidation has already been cancelled" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", cancelled_at: Time.current) }

        it "returns false" do
          expect(subject.cancel!).to be_falsey
        end
      end

      context "when the invalidation has already completed processing" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", completed_at: Time.current) }

        it "returns false" do
          expect(subject.cancel!).to be_falsey
        end
      end
    end

    describe "#completed?" do
      context "when completed_at is nil" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", completed_at: nil) }

        it "returns false" do
          expect(subject.completed?).to eq(false)
        end
      end

      context "when completed_at is set" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", completed_at: Time.current) }

        it "returns true" do
          expect(subject.completed?).to eq(true)
        end
      end
    end

    describe "#count!" do
      before do
        3.times do
          FactoryGirl.create(:validated_signature, ip_address: "10.0.1.1")
        end
      end

      subject { FactoryGirl.create(:invalidation, ip_address: "10.0.1.1") }

      it "updates the matching_count" do
        expect {
          subject.count!
        }.to change {
          subject.matching_count
        }.from(0).to(3)
      end

      it "updates the counted_at timestamp" do
        expect {
          subject.count!
        }.to change {
          subject.counted_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end

      context "when the invalidation in no longer pending" do
        subject { FactoryGirl.create(:invalidation, ip_address: "10.0.1.1", started_at: Time.current) }

        it "returns false" do
          expect(subject.count!).to be_falsey
        end
      end
    end

    describe "#enqueued?" do
      context "when enqueued_at is nil" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", enqueued_at: nil) }

        it "returns false" do
          expect(subject.enqueued?).to eq(false)
        end
      end

      context "when enqueued_at is set" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", enqueued_at: Time.current) }

        it "returns true" do
          expect(subject.enqueued?).to eq(true)
        end
      end
    end

    describe "#start!" do
      subject { FactoryGirl.create(:invalidation, ip_address: "10.0.1.1") }

      let(:job) do
        {
          job: InvalidateSignaturesJob,
          args: [
            { "_aj_globalid" => "gid://epets/Invalidation/#{subject.id}" }
          ],
          queue: "high_priority"
        }
      end

      it "enqueues the invalidate signatures job" do
        expect {
          subject.start!
        }.to change {
          enqueued_jobs
        }.from([]).to([job])
      end

      it "updates the enqueued_at timestamps" do
        expect {
          subject.start!
        }.to change {
          subject.enqueued_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end

      context "when the invalidation in no longer pending" do
        subject { FactoryGirl.create(:invalidation, ip_address: "10.0.1.1", started_at: Time.current) }

        it "returns false" do
          expect(subject.start!).to be_falsey
        end
      end
    end

    describe "#started?" do
      context "when started_at is nil" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: nil) }

        it "returns false" do
          expect(subject.started?).to eq(false)
        end
      end

      context "when started_at is set" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: Time.current) }

        it "returns true" do
          expect(subject.started?).to eq(true)
        end
      end
    end

    describe "#pending?" do
      context "by default" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs") }

        it "returns true" do
          expect(subject.pending?).to eq(true)
        end
      end

      context "when a invalidation is enqueued" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", enqueued_at: Time.current) }

        it "returns false" do
          expect(subject.pending?).to eq(false)
        end
      end

      context "when a invalidation is running" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: Time.current) }

        it "returns false" do
          expect(subject.pending?).to eq(false)
        end
      end

      context "when a invalidation has been cancelled" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", cancelled_at: Time.current) }

        it "returns false" do
          expect(subject.pending?).to eq(false)
        end
      end

      context "when a invalidation has been completed" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", completed_at: Time.current) }

        it "returns false" do
          expect(subject.pending?).to eq(false)
        end
      end
    end

    describe "#running?" do
      context "by default" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs") }

        it "returns false" do
          expect(subject.running?).to eq(false)
        end
      end

      context "when a invalidation is running" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: Time.current) }

        it "returns true" do
          expect(subject.running?).to eq(true)
        end
      end

      context "when a invalidation has been cancelled" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: Time.current, cancelled_at: Time.current) }

        it "returns false" do
          expect(subject.running?).to eq(false)
        end
      end

      context "when a invalidation has been completed" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", started_at: Time.current, completed_at: Time.current) }

        it "returns false" do
          expect(subject.running?).to eq(false)
        end
      end
    end

    describe "#percent_completed" do
      context "when matching_count is zero" do
        context "and the invalidation has not started" do
          subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", matching_count: 0, invalidated_count: 0) }

          it "returns 0" do
            expect(subject.percent_completed).to eq(0)
          end
        end

        context "and the invalidation has started" do
          subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", matching_count: 0, invalidated_count: 0, started_at: Time.current) }

          it "returns 100" do
            expect(subject.percent_completed).to eq(100)
          end
        end

        context "and the invalidation has completed" do
          subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", matching_count: 0, invalidated_count: 0, started_at: Time.current, completed_at: Time.current) }

          it "returns 100" do
            expect(subject.percent_completed).to eq(100)
          end
        end
      end

      context "when matching_count is not zero" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", matching_count: 100, invalidated_count: 50, started_at: Time.current) }

        it "returns the percentage of completed invalidations" do
          expect(subject.percent_completed).to eq(50)
        end
      end

      context "when invalidated_count is a negative number" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", matching_count: 100, invalidated_count: -50, started_at: Time.current) }

        it "returns 0" do
          expect(subject.percent_completed).to eq(0)
        end
      end

      context "when invalidated_count is greater than matching_count" do
        subject { FactoryGirl.create(:invalidation, name: "Joe Bloggs", matching_count: 50, invalidated_count: 100, started_at: Time.current) }

        it "returns 100" do
          expect(subject.percent_completed).to eq(100)
        end
      end
    end

    describe "#matching_signatures" do
      context "when filtering by petition" do
        let!(:petition_1) { FactoryGirl.create(:open_petition) }
        let!(:petition_2) { FactoryGirl.create(:open_petition) }
        let!(:signature_1) { FactoryGirl.create(:validated_signature, petition: petition_1) }
        let!(:signature_2) { FactoryGirl.create(:validated_signature, petition: petition_2) }

        subject { FactoryGirl.create(:invalidation, petition: petition_1) }

        it "includes signatures for petition 1" do
          expect(subject.matching_signatures).to include(signature_1)
        end

        it "excludes signatures for petition 2" do
          expect(subject.matching_signatures).not_to include(signature_2)
        end
      end

      context "when filtering by name" do
        let!(:petition) { FactoryGirl.create(:open_petition) }
        let!(:signature_1) { FactoryGirl.create(:validated_signature, name: "Joe Public", petition: petition) }
        let!(:signature_2) { FactoryGirl.create(:validated_signature, name: "John Doe", petition: petition) }

        subject { FactoryGirl.create(:invalidation, name: "Joe Public") }

        it "includes signatures that match" do
          expect(subject.matching_signatures).to include(signature_1)
        end

        it "excludes signatures that don't match" do
          expect(subject.matching_signatures).not_to include(signature_2)
        end

        context "and the filter includes a LIKE wildcard" do
          subject { FactoryGirl.create(:invalidation, name: "Joe %") }

          it "includes signatures that match" do
            expect(subject.matching_signatures).to include(signature_1)
          end

          it "excludes signatures that don't match" do
            expect(subject.matching_signatures).not_to include(signature_2)
          end
        end
      end

      context "when filtering by postcode" do
        let!(:petition) { FactoryGirl.create(:open_petition) }
        let!(:signature_1) { FactoryGirl.create(:validated_signature, postcode: "SW1A 0AA", petition: petition) }
        let!(:signature_2) { FactoryGirl.create(:validated_signature, postcode: "E1 6PL", petition: petition) }

        subject { FactoryGirl.create(:invalidation, postcode: "SW1A0AA") }

        it "includes signatures that match" do
          expect(subject.matching_signatures).to include(signature_1)
        end

        it "excludes signatures that don't match" do
          expect(subject.matching_signatures).not_to include(signature_2)
        end
      end

      context "when filtering by ip_address" do
        let!(:petition) { FactoryGirl.create(:open_petition) }
        let!(:signature_1) { FactoryGirl.create(:validated_signature, ip_address: "10.0.1.1", petition: petition) }
        let!(:signature_2) { FactoryGirl.create(:validated_signature, ip_address: "192.168.1.1", petition: petition) }

        subject { FactoryGirl.create(:invalidation, ip_address: "10.0.1.1") }

        it "includes signatures that match" do
          expect(subject.matching_signatures).to include(signature_1)
        end

        it "excludes signatures that don't match" do
          expect(subject.matching_signatures).not_to include(signature_2)
        end
      end

      context "when filtering by email" do
        let!(:petition) { FactoryGirl.create(:open_petition) }
        let!(:signature_1) { FactoryGirl.create(:validated_signature, email: "joe@public.com", petition: petition) }
        let!(:signature_2) { FactoryGirl.create(:validated_signature, email: "john@doe.com", petition: petition) }

        subject { FactoryGirl.create(:invalidation, email: "joe@public.com") }

        it "includes signatures that match" do
          expect(subject.matching_signatures).to include(signature_1)
        end

        it "excludes signatures that don't match" do
          expect(subject.matching_signatures).not_to include(signature_2)
        end

        context "and the filter includes a LIKE wildcard" do
          subject { FactoryGirl.create(:invalidation, email: "%@public.com") }

          it "includes signatures that match" do
            expect(subject.matching_signatures).to include(signature_1)
          end

          it "excludes signatures that don't match" do
            expect(subject.matching_signatures).not_to include(signature_2)
          end
        end
      end

      context "when filtering by date range" do
        let!(:petition) { FactoryGirl.create(:open_petition) }

        context "and just the start date is specified" do
          let!(:signature_1) { FactoryGirl.create(:validated_signature, created_at: 2.weeks.ago, petition: petition) }
          let!(:signature_2) { FactoryGirl.create(:validated_signature, created_at: 4.weeks.ago, petition: petition) }

          subject { FactoryGirl.create(:invalidation, created_after: 3.weeks.ago) }

          it "includes signatures that match" do
            expect(subject.matching_signatures).to include(signature_1)
          end

          it "excludes signatures that don't match" do
            expect(subject.matching_signatures).not_to include(signature_2)
          end
        end

        context "and just the end date is specified" do
          let!(:signature_1) { FactoryGirl.create(:validated_signature, created_at: 4.weeks.ago, petition: petition) }
          let!(:signature_2) { FactoryGirl.create(:validated_signature, created_at: 2.weeks.ago, petition: petition) }

          subject { FactoryGirl.create(:invalidation, created_before: 3.weeks.ago) }

          it "includes signatures that match" do
            expect(subject.matching_signatures).to include(signature_1)
          end

          it "excludes signatures that don't match" do
            expect(subject.matching_signatures).not_to include(signature_2)
          end
        end

        context "and both the start date and end date are specified" do
          let!(:signature_1) { FactoryGirl.create(:validated_signature, created_at: 4.weeks.ago, petition: petition) }
          let!(:signature_2) { FactoryGirl.create(:validated_signature, created_at: 2.weeks.ago, petition: petition) }

          subject { FactoryGirl.create(:invalidation, created_before: 3.weeks.ago, created_after: 5.weeks.ago) }

          it "includes signatures that match" do
            expect(subject.matching_signatures).to include(signature_1)
          end

          it "excludes signatures that don't match" do
            expect(subject.matching_signatures).not_to include(signature_2)
          end
        end
      end

      context "when filtering by constituency_id" do
        let!(:petition) { FactoryGirl.create(:open_petition) }
        let!(:constituency_1) { FactoryGirl.create(:constituency, external_id: "3314") }
        let!(:constituency_2) { FactoryGirl.create(:constituency, external_id: "3352") }
        let!(:signature_1) { FactoryGirl.create(:validated_signature, constituency_id: "3314", petition: petition) }
        let!(:signature_2) { FactoryGirl.create(:validated_signature, constituency_id: "3352", petition: petition) }

        subject { FactoryGirl.create(:invalidation, constituency_id: "3314") }

        it "includes signatures that match" do
          expect(subject.matching_signatures).to include(signature_1)
        end

        it "excludes signatures that don't match" do
          expect(subject.matching_signatures).not_to include(signature_2)
        end
      end

      context "when filtering by location_code" do
        let!(:petition) { FactoryGirl.create(:open_petition) }
        let!(:united_kingdom) { FactoryGirl.create(:location, code: "GB", name: "United Kingdom") }
        let!(:australia) { FactoryGirl.create(:location, code: "AU", name: "Australia") }
        let!(:signature_1) { FactoryGirl.create(:validated_signature, location_code: "GB", petition: petition) }
        let!(:signature_2) { FactoryGirl.create(:validated_signature, location_code: "AU", petition: petition) }

        subject { FactoryGirl.create(:invalidation, location_code: "GB") }

        it "includes signatures that match" do
          expect(subject.matching_signatures).to include(signature_1)
        end

        it "excludes signatures that don't match" do
          expect(subject.matching_signatures).not_to include(signature_2)
        end
      end
    end

    describe "#invalidate!" do
      let!(:petition) { FactoryGirl.create(:open_petition) }
      let!(:signature_1) { FactoryGirl.create(:validated_signature, ip_address: "10.0.1.1", petition: petition) }
      let!(:signature_2) { FactoryGirl.create(:validated_signature, ip_address: "192.168.1.1", petition: petition) }
      let!(:signature_3) { FactoryGirl.create(:validated_signature, ip_address: "10.0.1.1", petition: petition) }
      let!(:signature_4) { FactoryGirl.create(:validated_signature, ip_address: "192.168.1.2", petition: petition) }
      let!(:signature_5) { FactoryGirl.create(:validated_signature, ip_address: "10.0.1.1", petition: petition) }

      subject { FactoryGirl.create(:invalidation, ip_address: "10.0.1.1") }

      it "sets the matching_count" do
        expect {
          subject.invalidate!
        }.to change {
          subject.reload.matching_count
        }.from(0).to(3)
      end

      it "increments the invalidated_count after each invalidation" do
        expect(subject).to receive(:increment!).with(:invalidated_count).exactly(3).times.and_call_original
        subject.invalidate!
      end

      it "sets the invalidated_count" do
        expect {
          subject.invalidate!
        }.to change {
          subject.reload.invalidated_count
        }.from(0).to(3)
      end

      it "sets the started_at timestamp" do
        expect {
          subject.invalidate!
        }.to change {
          subject.reload.started_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end

      it "sets the completed_at timestamp" do
        expect {
          subject.invalidate!
        }.to change {
          subject.reload.completed_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end

      it "adds the invalidated signatures to the signatures association" do
        expect {
          subject.invalidate!
        }.to change {
          subject.signatures.count
        }.from(0).to(3)
      end

      context "when the invalidation has already completed processing" do
        subject { FactoryGirl.create(:invalidation, ip_address: "10.0.1.1", completed_at: Time.current) }

        it "returns false" do
          expect(subject.invalidate!).to be_falsey
        end
      end

      context "when cancelled before starting" do
        before do
          subject.cancel!
        end

        it "doesn't start" do
          expect {
            subject.invalidate!
          }.not_to change {
            subject.reload.started_at
          }
        end
      end

      context "when cancelled during processing" do
        before do
          200.times do
            FactoryGirl.create(:validated_signature, ip_address: "10.0.1.1", petition: petition)
          end
        end

        it "doesn't finish" do
          allow(subject).to receive(:cancelled?).and_return(false, true)

          subject.invalidate!
          subject.reload

          expect(subject.matching_count).to eq(203)
          expect(subject.invalidated_count).to eq(100)
          expect(subject.signatures.count).to eq(100)
        end
      end
    end
  end
end
