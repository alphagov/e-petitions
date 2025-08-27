require 'rails_helper'
require_relative '../department_examples'
require_relative '../taggable_examples'
require_relative '../topic_examples'

RSpec.describe Archived::Petition, type: :model do
  subject(:petition){ described_class.new }

  describe "associations" do
    describe "parliament" do
      it { is_expected.to belong_to(:parliament).required(true).inverse_of(:petitions) }

      it "is required" do
        expect {
          petition.valid?
        }.to change {
          petition.errors[:parliament]
        }.from([]).to(["Parliament can’t be blank"])
      end
    end

    describe "government_response" do
      it { is_expected.to have_one(:government_response) }
    end

    describe "rejection" do
      it { is_expected.to have_one(:rejection) }
    end
  end

  describe "callbacks" do
    describe "updating the scheduled debate date" do
      context "when the debate threshold has been reached" do
        context "and the debate date is changed to nil" do
          subject(:petition) {
            FactoryBot.create(:archived_petition,
              debate_threshold_reached_at: 6.months.ago,
              scheduled_debate_date: 2.days.from_now,
              debate_state: "scheduled"
            )
          }

          it "sets the debate state to 'awaiting'" do
            expect {
              petition.update(scheduled_debate_date: nil)
            }.to change {
              petition.debate_state
            }.from("scheduled").to("awaiting")
          end
        end

        context "and the debate date is in the future" do
          subject(:petition) {
            FactoryBot.create(:archived_petition,
              debate_threshold_reached_at: 6.months.ago,
              scheduled_debate_date: nil,
              debate_state: "awaiting"
            )
          }

          it "sets the debate state to 'scheduled'" do
            expect {
              petition.update(scheduled_debate_date: 2.days.from_now)
            }.to change {
              petition.debate_state
            }.from("awaiting").to("scheduled")
          end
        end

        context "and the debate date is in the past" do
          subject(:petition) {
            FactoryBot.create(:archived_petition,
              debate_threshold_reached_at: 6.months.ago,
              scheduled_debate_date: nil,
              debate_state: "awaiting"
            )
          }

          it "sets the debate state to 'debated'" do
            expect {
              petition.update(scheduled_debate_date: 2.days.ago)
            }.to change {
              petition.debate_state
            }.from("awaiting").to("debated")
          end
        end

        context "and the debate date is not changed" do
          subject(:petition) {
            FactoryBot.create(:archived_petition,
              debate_threshold_reached_at: 6.months.ago,
              scheduled_debate_date: Date.yesterday,
              debate_state: "debated"
            )
          }

          it "does not change the debate state" do
            expect {
              petition.update(special_consideration: true)
            }.not_to change {
              petition.debate_state
            }
          end
        end
      end

      context "when the debate threshold has not been reached" do
        context "and the debate date is changed to nil" do
          subject(:petition) {
            FactoryBot.create(:archived_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: 2.days.from_now,
              debate_state: "scheduled"
            )
          }

          it "sets the debate state to 'awaiting'" do
            expect {
              petition.update(scheduled_debate_date: nil)
            }.to change {
              petition.debate_state
            }.from("scheduled").to("pending")
          end
        end

        context "and the debate date is in the future" do
          subject(:petition) {
            FactoryBot.create(:archived_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: nil,
              debate_state: "pending"
            )
          }

          it "sets the debate state to 'scheduled'" do
            expect {
              petition.update(scheduled_debate_date: 2.days.from_now)
            }.to change {
              petition.debate_state
            }.from("pending").to("scheduled")
          end
        end

        context "and the debate date is in the past" do
          subject(:petition) {
            FactoryBot.create(:archived_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: nil,
              debate_state: "pending"
            )
          }

          it "sets the debate state to 'debated'" do
            expect {
              petition.update(scheduled_debate_date: 2.days.ago)
            }.to change {
              petition.debate_state
            }.from("pending").to("debated")
          end
        end

        context "and the debate date is not changed" do
          subject(:petition) {
            FactoryBot.create(:archived_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: Date.yesterday,
              debate_state: "debated"
            )
          }

          it "does not change the debate state" do
            expect {
              petition.update(special_consideration: true)
            }.not_to change {
              petition.debate_state
            }
          end
        end
      end
    end
  end

  describe ".search" do
    let!(:petition_1) do
      FactoryBot.create(:archived_petition, :closed, action: "Wombles are great", created_at: 1.year.ago, signature_count: 100)
    end

    let!(:petition_2) do
      FactoryBot.create(:archived_petition, :closed, background: "The Wombles of Wimbledon", created_at: 2.years.ago, signature_count: 200)
    end

    let!(:petition_3) do
      FactoryBot.create(:archived_petition, :closed, additional_details: "Are wombling free", created_at: 3.years.ago, signature_count: 300)
    end

    it "searches based upon action" do
      expect(Archived::Petition.search(q: "wombles")).to include(petition_1)
    end

    it "searches based upon background" do
      expect(Archived::Petition.search(q: "wimbledon")).to include(petition_2)
    end

    it "searches based upon additional_details" do
      expect(Archived::Petition.search(q: "wombling")).to include(petition_3)
    end

    it "sorts the results by the highest number of signatures" do
      expect(Archived::Petition.search(q: "Petition").to_a).to eq([petition_3, petition_2, petition_1])
    end
  end

  describe ".by_created_at" do
    let!(:petition_1) { FactoryBot.create(:archived_petition, created_at: 3.years.ago) }
    let!(:petition_2) { FactoryBot.create(:archived_petition, created_at: 1.year.ago) }
    let!(:petition_3) { FactoryBot.create(:archived_petition, created_at: 2.years.ago) }
    let(:petitions) { [petition_1, petition_3, petition_2] }

    it 'returns archived petitions ordered by the created_at timestamp' do
      expect(Archived::Petition.by_created_at).to eq(petitions)
    end
  end

  describe ".by_most_signatures" do
    let!(:petition_1) { FactoryBot.create(:archived_petition, signature_count: 100) }
    let!(:petition_2) { FactoryBot.create(:archived_petition, signature_count: 10) }
    let!(:petition_3) { FactoryBot.create(:archived_petition, signature_count: 50) }
    let(:petitions) { [petition_1, petition_3, petition_2] }

    it 'returns archived petitions ordered by highest number of signatures' do
      expect(Archived::Petition.by_most_signatures).to eq(petitions)
    end
  end

  describe ".with_response" do
    before do
      @p1 = FactoryBot.create(:archived_petition, :response)
      @p2 = FactoryBot.create(:archived_petition)
      @p3 = FactoryBot.create(:archived_petition, :response)
      @p4 = FactoryBot.create(:archived_petition)
    end

    it "returns only the petitions have a government response timestamp" do
      expect(described_class.with_response).to match_array([@p1, @p3])
    end
  end

  describe ".visible" do
    let!(:stopped_petition) { FactoryBot.create(:archived_petition, :stopped) }
    let!(:closed_petition) { FactoryBot.create(:archived_petition, :closed) }
    let!(:rejected_petition) { FactoryBot.create(:archived_petition, :rejected) }
    let!(:hidden_petition) { FactoryBot.create(:archived_petition, :hidden) }

    it "doesn't include stopped petitions" do
      expect(described_class.visible).not_to include(stopped_petition)
    end

    it "includes closed petitions" do
      expect(described_class.visible).to include(closed_petition)
    end

    it "includes rejected petitions" do
      expect(described_class.visible).to include(rejected_petition)
    end

    it "doesn't include hidden petitions" do
      expect(described_class.visible).not_to include(hidden_petition)
    end
  end

  describe ".in_need_of_marking_as_debated" do
    context "when a petition is not in the the 'awaiting' debate state" do
      let!(:petition) { FactoryBot.create(:archived_petition) }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated).not_to include(petition)
      end
    end

    context "when a petition is awaiting a debate date" do
      let!(:petition) {
        FactoryBot.create(:archived_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: nil
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated).not_to include(petition)
      end
    end

    context "when a petition is awaiting a debate" do
      let!(:petition) {
        FactoryBot.create(:archived_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: 2.days.from_now
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated).not_to include(petition)
      end
    end

    context "when a petition debate date has passed but is still marked as 'awaiting'" do
      let(:petition) {
        FactoryBot.build(:archived_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        travel_to(2.days.ago) do
          petition.save
        end
      end

      it "finds the petition" do
        expect(described_class.in_need_of_marking_as_debated).to include(petition)
      end
    end

    context "when a petition debate date has passed and it marked as 'debated'" do
      let!(:petition) {
        FactoryBot.create(:archived_petition,
          debate_state: 'debated',
          scheduled_debate_date: 2.days.ago
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated).not_to include(petition)
      end
    end
  end

  describe ".mark_petitions_as_debated!" do
    context "when a petition is in the scheduled debate state and the debate date has passed" do
      let(:petition) {
        FactoryBot.build(:archived_petition,
          debate_state: 'scheduled',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        travel_to(2.days.ago) do
          petition.save
        end
      end

      it "marks the petition as debated" do
        expect{
          described_class.mark_petitions_as_debated!
        }.to change{ petition.reload.debate_state }.from('scheduled').to('debated')
      end
    end

    context "when a petition is in the scheduled debate state and the debate date has not passed" do
      let(:petition) {
        FactoryBot.build(:archived_petition,
          debate_state: 'scheduled',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        petition.save
      end

      it "does not mark the petition as debated" do
        expect{
          described_class.mark_petitions_as_debated!
        }.not_to change{ petition.reload.debate_state }
      end
    end
  end

  describe ".can_anonymize?" do
    context "when there is an unanonymized petition not marked to remain anonymized" do
      let!(:petition) { FactoryBot.create(:archived_petition, anonymized_at: nil, do_not_anonymize: nil) }

      it "returns true" do
        expect(described_class.can_anonymize?).to eq true
      end
    end

    context "when there is an unanonymized petition marked to remain anonymized" do
      let!(:petition) { FactoryBot.create(:archived_petition, anonymized_at: nil, do_not_anonymize: true) }

      it "returns false" do
        expect(described_class.can_anonymize?).to eq false
      end
    end

    context "when there is one anonymized petition not marked to remain anonymized" do
      let!(:petition) { FactoryBot.create(:archived_petition, anonymized_at: 1.day.ago, do_not_anonymize: nil) }

      it "returns false" do
        expect(described_class.can_anonymize?).to eq false
      end
    end
  end

  describe ".anonymize_petitions!" do
    context "when a petition was rejected less than six months ago" do
      let!(:petition) do
        FactoryBot.create(
          :archived_petition,
          :rejected,
          rejected_at: 5.months.ago
        )
      end

      it "does not anonymize the petition" do
        expect {
          perform_enqueued_jobs {
            described_class.anonymize_petitions!
          }
        }.not_to change { petition.reload.anonymized? }
      end
    end

    context "when a petition was rejected six months ago" do
      let!(:petition) do
        FactoryBot.create(
          :archived_petition,
          :rejected,
          rejected_at: 6.months.ago
        )
      end

      it "anonymizes the petition" do
        expect {
          perform_enqueued_jobs {
            described_class.anonymize_petitions!
          }
        }.to change { petition.reload.anonymized? }
      end
    end

    context "when a petition was hidden less than six months ago" do
      let!(:petition) do
        FactoryBot.create(
          :archived_petition,
          :hidden,
          rejected_at: 5.months.ago
        )
      end

      it "does not anonymize the petition" do
        expect {
          perform_enqueued_jobs {
            described_class.anonymize_petitions!
          }
        }.not_to change { petition.reload.anonymized? }
      end
    end

    context "when a petition was hidden six months ago" do
      let!(:petition) do
        FactoryBot.create(
          :archived_petition,
          :hidden,
          rejected_at: 6.months.ago
        )
      end

      it "anonymises the petitions" do
        expect {
          perform_enqueued_jobs {
            described_class.anonymize_petitions!
          }
        }.to change { petition.reload.anonymized? }
      end
    end

    context "when a petition has closed less than six months ago" do
      let!(:petition) { FactoryBot.create(:archived_petition, :closed, closed_at: 5.months.ago) }

      it "does not anonymize the petition" do
        expect{
          perform_enqueued_jobs {
            described_class.anonymize_petitions!
          }
        }.not_to change{ petition.reload.anonymized? }
      end
    end

    context "when a petition has closed more than six months ago" do
      let!(:petition) { FactoryBot.create(:archived_petition, :closed, closed_at: 7.months.ago) }

      it "does anonymize the petition" do
        expect{
          perform_enqueued_jobs {
            described_class.anonymize_petitions!
          }
        }.to change{ petition.reload.anonymized? }.from(false).to(true)
      end
    end

    context "when a petition has been set to not be anonymized" do
      let!(:petition) { FactoryBot.create(:archived_petition, :closed, closed_at: 7.months.ago, do_not_anonymize: true) }

      it "does not anonymize the petition" do
        expect{
          perform_enqueued_jobs {
            described_class.anonymize_petitions!
          }
        }.not_to change{ petition.reload.anonymized? }
      end
    end
  end

  describe ".in_need_of_anonymizing" do
    context "when a petition is anonymized" do
      let!(:petition) { FactoryBot.create(:archived_petition, :closed, closed_at: 7.months.ago, anonymized_at: 1.week.ago) }

      it "doesn't return the petition" do
        expect(described_class.in_need_of_anonymizing).not_to include(petition)
      end
    end

    context "when a petition is not anonymized" do
      context "and it has been closed for less than six months" do
        let!(:petition) { FactoryBot.create(:archived_petition, :closed, closed_at: 5.months.ago, anonymized_at: nil) }

        it "doesn't return the petition" do
          expect(described_class.in_need_of_anonymizing).not_to include(petition)
        end
      end

      context "and it has been closed for more than six months" do
        let!(:petition) { FactoryBot.create(:archived_petition, :closed, closed_at: 7.months.ago, anonymized_at: nil) }

        it "returns the petition" do
          expect(described_class.in_need_of_anonymizing).to include(petition)
        end
      end

      context "and it has been rejected for less than six months" do
        let!(:petition) { FactoryBot.create(:archived_petition, :rejected, rejected_at: 5.months.ago, anonymized_at: nil) }

        it "doesn't return the petition" do
          expect(described_class.in_need_of_anonymizing).not_to include(petition)
        end
      end

      context "and it has been rejected for more than six months" do
        let!(:petition) { FactoryBot.create(:archived_petition, :rejected, rejected_at: 7.months.ago, anonymized_at: nil) }

        it "returns the petition" do
          expect(described_class.in_need_of_anonymizing).to include(petition)
        end
      end

      context "and it has been stopped for less than six months" do
        let!(:petition) { FactoryBot.create(:archived_petition, :stopped, stopped_at: 5.months.ago, anonymized_at: nil) }

        it "doesn't return the petition" do
          expect(described_class.in_need_of_anonymizing).not_to include(petition)
        end
      end

      context "and it has been stopped for more than six months" do
        let!(:petition) { FactoryBot.create(:archived_petition, :stopped, stopped_at: 7.months.ago, anonymized_at: nil) }

        it "returns the petition" do
          expect(described_class.in_need_of_anonymizing).to include(petition)
        end
      end
    end
  end

  describe "concerns" do
    it_behaves_like "a taggable model"
    it_behaves_like "a model with departments"
    it_behaves_like "a model with topics"
  end

  describe "#action" do
    it "defaults to nil" do
      expect(petition.action).to be_nil
    end

    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_length_of(:action).is_at_most(150) }
  end

  describe "#background" do
    it "defaults to nil" do
      expect(petition.background).to be_nil
    end

    it { is_expected.to validate_length_of(:background).is_at_most(300) }
  end

  describe "#additional_details" do
    it "defaults to nil" do
      expect(petition.additional_details).to be_nil
    end

    it { is_expected.to validate_length_of(:additional_details).is_at_most(1000) }
  end

  describe "#committee_note" do
    it "defaults to nil" do
      expect(petition.committee_note).to be_nil
    end

    it { is_expected.to validate_length_of(:committee_note).is_at_most(800) }
  end

  describe "#state" do
    it "defaults to 'closed'" do
      expect(petition.state).to eq("closed")
    end

    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_inclusion_of(:state).in_array(%w[stopped closed rejected hidden]) }
  end

  describe "#opened_at" do
    it "defaults to nil" do
      expect(petition.opened_at).to be_nil
    end
  end

  describe "#closed_at" do
    it "defaults to nil" do
      expect(petition.closed_at).to be_nil
    end

    it { is_expected.to validate_presence_of(:closed_at) }
  end

  describe "#rejected_at" do
    it "defaults to nil" do
      expect(petition.opened_at).to be_nil
    end
  end

  describe "#signature_count" do
    it "defaults to zero" do
      expect(petition.signature_count).to be_zero
    end
  end

  describe "#stopped?" do
    context "when petition is in a stopped state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :stopped) }

      it "returns true" do
        expect(petition.stopped?).to eq(true)
      end
    end

    context "when petition is in a closed state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :closed) }

      it "returns false" do
        expect(petition.stopped?).to eq(false)
      end
    end

    context "when petition is in a rejected state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :rejected) }

      it "returns false" do
        expect(petition.stopped?).to eq(false)
      end
    end

    context "when petition is in a hidden state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :hidden) }

      it "returns false" do
        expect(petition.stopped?).to eq(false)
      end
    end

    context "when petition is in a removed state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :removed) }

      it "returns false" do
        expect(petition.stopped?).to eq(false)
      end
    end
  end

  describe "#closed?" do
    context "when petition is in a stopped state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :stopped) }

      it "returns false" do
        expect(petition.closed?).to eq(false)
      end
    end

    context "when petition is in a closed state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :closed) }

      it "returns true" do
        expect(petition.closed?).to eq(true)
      end
    end

    context "when petition is in a rejected state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :rejected) }

      it "returns false" do
        expect(petition.closed?).to eq(false)
      end
    end

    context "when petition is in a hidden state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :hidden) }

      it "returns false" do
        expect(petition.closed?).to eq(false)
      end
    end

    context "when petition is in a removed state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :removed) }

      it "returns false" do
        expect(petition.closed?).to eq(false)
      end
    end
  end

  describe "#rejected?" do
    context "when petition is in a stopped state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :stopped) }

      it "returns false" do
        expect(petition.rejected?).to eq(false)
      end
    end

    context "when petition is in a closed state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :closed) }

      it "returns false" do
        expect(petition.rejected?).to eq(false)
      end
    end

    context "when petition is in a rejected state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :rejected) }

      it "returns true" do
        expect(petition.rejected?).to eq(true)
      end
    end

    context "when petition is in a hidden state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :hidden) }

      it "returns false" do
        expect(petition.rejected?).to eq(false)
      end
    end

    context "when petition is in a removed state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :removed) }

      it "returns false" do
        expect(petition.rejected?).to eq(false)
      end
    end
  end

  describe "#hidden?" do
    context "when petition is in a stopped state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :stopped) }

      it "returns false" do
        expect(petition.hidden?).to eq(false)
      end
    end

    context "when petition is in a closed state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :closed) }

      it "returns false" do
        expect(petition.hidden?).to eq(false)
      end
    end

    context "when petition is in a rejected state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :rejected) }

      it "returns false" do
        expect(petition.hidden?).to eq(false)
      end
    end

    context "when petition is in a hidden state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :hidden) }

      it "returns false" do
        expect(petition.hidden?).to eq(true)
      end
    end

    context "when petition is in a removed state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :removed) }

      it "returns false" do
        expect(petition.hidden?).to eq(false)
      end
    end
  end

  describe "#duration" do
    context "when the parliament petition duration is nil" do
      let(:parliament) { FactoryBot.create(:parliament, petition_duration: nil) }

      context "and the petition was not published" do
        let(:petition) { FactoryBot.create(:archived_petition, :rejected, parliament: parliament) }

        it "returns 0" do
          expect(petition.duration).to eq(0)
        end
      end

      context "and the petition was published for three months" do
        let(:opened_at) { 2.years.ago }
        let(:closed_at) { opened_at + 3.months }
        let(:petition) { FactoryBot.create(:archived_petition, opened_at: opened_at, closed_at: closed_at, parliament: parliament) }

        it "returns 3" do
          expect(petition.duration).to eq(3)
        end
      end

      context "and the petition was published for six months" do
        let(:opened_at) { 2.years.ago }
        let(:closed_at) { opened_at + 6.months }
        let(:petition) { FactoryBot.create(:archived_petition, opened_at: opened_at, closed_at: closed_at, parliament: parliament) }

        it "returns 3" do
          expect(petition.duration).to eq(6)
        end
      end

      context "and the petition was published for nine months" do
        let(:opened_at) { 2.years.ago }
        let(:closed_at) { opened_at + 9.months }
        let(:petition) { FactoryBot.create(:archived_petition, opened_at: opened_at, closed_at: closed_at, parliament: parliament) }

        it "returns 3" do
          expect(petition.duration).to eq(9)
        end
      end

      context "and the petition was published for twelve months" do
        let(:opened_at) { 2.years.ago }
        let(:closed_at) { opened_at + 12.months }
        let(:petition) { FactoryBot.create(:archived_petition, opened_at: opened_at, closed_at: closed_at, parliament: parliament) }

        it "returns 3" do
          expect(petition.duration).to eq(12)
        end
      end

      context "and the petition was published for an arbitrary length of time" do
        let(:opened_at) { 2.years.ago }
        let(:closed_at) { opened_at + 45.days }
        let(:petition) { FactoryBot.create(:archived_petition, opened_at: opened_at, closed_at: closed_at, parliament: parliament) }

        it "returns a fractional number of months assuming that 1 month == 30 days" do
          expect(petition.duration).to be_within(0.1).of(1.5)
        end
      end
    end

    context "when the parliament petition duration is not nil" do
      let(:parliament) { FactoryBot.create(:parliament, petition_duration: 6) }
      let(:petition) { FactoryBot.create(:archived_petition, parliament: parliament) }

      it "returns the duration from the parliament" do
        expect(petition.duration).to eq(6)
      end
    end
  end

  describe "#threshold_for_response" do
    it { is_expected.to delegate_method(:threshold_for_response).to(:parliament) }
  end

  describe "#threshold_for_debate" do
    it { is_expected.to delegate_method(:threshold_for_response).to(:parliament) }
  end

  describe "#closed_early_due_to_election?" do
    let(:parliament) { FactoryBot.create(:parliament, :dissolved, :archived, dissolution_at: "2015-05-18T23:59:59") }
    let(:petition) { FactoryBot.create(:archived_petition, parliament: parliament, closed_at: closed_at) }

    context "when closed_at is before the dissolution_at timestamp" do
      let(:closed_at) { "2015-05-01T00:00:00" }

      it "returns false" do
        expect(petition.closed_early_due_to_election?).to eq(false)
      end
    end

    context "when closed_at is equal to the dissolution_at timestamp" do
      let(:closed_at) { "2015-05-18T23:59:59" }

      it "returns true" do
        expect(petition.closed_early_due_to_election?).to eq(true)
      end
    end

    context "when closed_at is after the dissolution_at timestamp" do
      let(:closed_at) { "2015-06-01T00:00:00" }

      it "returns false" do
        expect(petition.closed_early_due_to_election?).to eq(false)
      end
    end
  end

  describe "#threshold_for_response_reached?" do
    let(:parliament) { FactoryBot.create(:parliament, threshold_for_response: 500) }
    let(:petition) { FactoryBot.create(:archived_petition, parliament: parliament, signature_count: signature_count) }

    context "when the signature count is less than the threshold" do
      let(:signature_count) { 250 }

      it "returns false" do
        expect(petition.threshold_for_response_reached?).to eq(false)
      end
    end

    context "when the signature count is equal to the threshold" do
      let(:signature_count) { 500 }

      it "returns true" do
        expect(petition.threshold_for_response_reached?).to eq(true)
      end
    end

    context "when the signature count is greater than the threshold" do
      let(:signature_count) { 750 }

      it "returns true" do
        expect(petition.threshold_for_response_reached?).to eq(true)
      end
    end
  end

  describe "#threshold_for_debate_reached?" do
    let(:parliament) { FactoryBot.create(:parliament, threshold_for_debate: 5000) }
    let(:petition) { FactoryBot.create(:archived_petition, parliament: parliament, signature_count: signature_count) }

    context "when the signature count is less than the threshold" do
      let(:signature_count) { 2500 }

      it "returns false" do
        expect(petition.threshold_for_debate_reached?).to eq(false)
      end
    end

    context "when the signature count is equal to the threshold" do
      let(:signature_count) { 5000 }

      it "returns true" do
        expect(petition.threshold_for_debate_reached?).to eq(true)
      end
    end

    context "when the signature count is greater than the threshold" do
      let(:signature_count) { 7500 }

      it "returns true" do
        expect(petition.threshold_for_debate_reached?).to eq(true)
      end
    end
  end

  describe "#signatures_by_constituency" do
    let(:petition) { FactoryBot.create(:archived_petition, signatures_by_constituency: signatures_by_constituency) }

    let(:signatures_by_constituency) do
      { "3427" => 123, "3320" => 456 }
    end

    before do
      FactoryBot.create(:constituency, :coventry_north_east)
      FactoryBot.create(:constituency, :bethnal_green_and_bow)
    end

    it "returns an array of constituency signature details" do
      expect(petition.signatures_by_constituency).to eq [
        {
          name: "Bethnal Green and Bow",
          ons_code: "E14000555",
          mp: "Rushanara Ali MP",
          signature_count: 456
        },
        {
          name: "Coventry North East",
          ons_code: "E14000649",
          mp: "Colleen Fletcher MP",
          signature_count: 123
        }
      ]
    end

    it "only finds the constituencies once" do
      expect(Constituency).to receive(:where).with(external_id: %w[3427 3320]).once.and_call_original

      petition.signatures_by_constituency
      petition.signatures_by_constituency
    end
  end

  describe "#signatures_by_country" do
    let(:petition) { FactoryBot.create(:archived_petition, signatures_by_country: signatures_by_country) }

    let(:signatures_by_country) do
      { "GB" => 1234, "US" => 56 }
    end

    before do
      FactoryBot.create(:location, code: "GB", name: "United Kingdom")
      FactoryBot.create(:location, code: "US", name: "United States")
    end

    it "returns an array of country signature details" do
      expect(petition.signatures_by_country).to eq [
        {
          name: "United Kingdom",
          code: "GB",
          signature_count: 1234
        },
        {
          name: "United States",
          code: "US",
          signature_count: 56
        }
      ]
    end

    it "only finds the countries once" do
      expect(Location).to receive(:where).with(code: %w[GB US]).once.and_call_original

      petition.signatures_by_country
      petition.signatures_by_country
    end
  end

  describe "#signatures_by_region" do
    let(:petition) { FactoryBot.create(:archived_petition, signatures_by_constituency: signatures_by_constituency) }

    let(:signatures_by_constituency) do
      { "3427" => 123, "3320" => 456 }
    end

    before do
      FactoryBot.create(:constituency, :coventry_north_east)
      FactoryBot.create(:constituency, :bethnal_green_and_bow)
    end

    it "returns an array of region signature details" do
      expect(petition.signatures_by_region).to eq [
        {
          name: "West Midlands",
          ons_code: "F",
          signature_count: 123
        },
        {
          name: "London",
          ons_code: "H",
          signature_count: 456
        }
      ]
    end

    it "only finds the constituencies once" do
      expect(Constituency).to receive(:where).with(external_id: %w[3427 3320]).once.and_call_original

      petition.signatures_by_region
      petition.signatures_by_region
    end

    it "only finds the regions once" do
      expect(Region).to receive(:where).with(external_id: %w[111 113]).once.and_call_original

      petition.signatures_by_region
      petition.signatures_by_region
    end
  end

  describe "#get_email_requested_at_for" do
    let(:requested_at) { Time.current }

    %w[government_response debate_scheduled debate_outcome petition_email].each do |timestamp|
      context "when nothing has been requested for '#{timestamp}'" do
        let(:petition) { FactoryBot.create(:archived_petition, "email_requested_for_#{timestamp}_at": nil) }

        it "returns nil" do
          expect(petition.get_email_requested_at_for(timestamp)).to be_nil
        end
      end

      context "when an email has been requested for '#{timestamp}'" do
        let(:petition) { FactoryBot.create(:archived_petition, "email_requested_for_#{timestamp}_at": requested_at) }

        it "returns the timestamp" do
          expect(petition.get_email_requested_at_for(timestamp)).to be_usec_precise_with(requested_at)
        end
      end
    end
  end

  describe '#set_email_requested_at_for' do
    let(:petition) { FactoryBot.create(:archived_petition) }
    let(:requested_at) { Time.current }

    %w[government_response debate_scheduled debate_outcome petition_email].each do |timestamp|
      it "sets the email requested timestamp for '#{timestamp}'" do
        expect {
          petition.set_email_requested_at_for(timestamp, to: requested_at)
        }.to change {
          petition[:"email_requested_for_#{timestamp}_at"]
        }.from(nil).to(be_usec_precise_with(requested_at))
      end
    end
  end

  describe "#signatures_to_email_for" do
    let!(:petition) { FactoryBot.create(:archived_petition) }
    let!(:creator) { FactoryBot.create(:archived_signature, petition: petition, creator: true) }
    let!(:pending) { FactoryBot.create(:archived_signature, petition: petition, state: "pending") }
    let!(:fraudulent) { FactoryBot.create(:archived_signature, petition: petition, state: "fraudulent") }
    let!(:invalidated) { FactoryBot.create(:archived_signature, petition: petition, state: "invalidated") }
    let!(:subscribed) { FactoryBot.create(:archived_signature, petition: petition) }
    let!(:unsubscribed) { FactoryBot.create(:archived_signature, petition: petition, notify_by_email: false) }

    let(:requested_at) { 6.days.ago }

    %w[government_response debate_scheduled debate_outcome petition_email].each do |timestamp|
      context "when the email requested timestamp for '#{timestamp}' is not set" do
        it "raises an ArgumentError" do
          expect {
            petition.signatures_to_email_for(timestamp)
          }.to raise_error(ArgumentError, /#{timestamp} email has not been requested/)
        end
      end

      context "when the email requested timestamp for '#{timestamp}' is set" do
        before do
          petition.set_email_requested_at_for(timestamp, to: requested_at)
        end

        it "includes subscribed signatures" do
          expect(petition.signatures_to_email_for(timestamp)).to match_array([creator, subscribed])
        end

        it "does not include unsubscribed signatures" do
          expect(petition.signatures_to_email_for(timestamp)).not_to include(unsubscribed)
        end

        it "does not include pending signatures" do
          expect(petition.signatures_to_email_for(timestamp)).not_to include(pending)
        end

        it "does not include fraudulent signatures" do
          expect(petition.signatures_to_email_for(timestamp)).not_to include(fraudulent)
        end

        it "does not include invalidated signatures" do
          expect(petition.signatures_to_email_for(timestamp)).not_to include(invalidated)
        end

        context "and the email sent timestamp for '#{timestamp}' is before the requested timestamp" do
          before do
            subscribed.set_email_sent_at_for(timestamp, to: requested_at - 1.day)
          end

          it "includes the signature" do
            expect(petition.signatures_to_email_for(timestamp)).to include(subscribed)
          end
        end

        context "and the email sent timestamp for '#{timestamp}' is the same as the requested timestamp" do
          before do
            subscribed.set_email_sent_at_for(timestamp, to: requested_at)
          end

          it "does not include the signature" do
            expect(petition.signatures_to_email_for(timestamp)).not_to include(subscribed)
          end
        end

        context "and the email sent timestamp for '#{timestamp}' is after as the requested timestamp" do
          before do
            subscribed.set_email_sent_at_for(timestamp, to: requested_at + 1.day)
          end

          it "does not include the signature" do
            expect(petition.signatures_to_email_for(timestamp)).not_to include(subscribed)
          end
        end
      end
    end
  end

  describe "#anonymize!" do
    let(:petition) { FactoryBot.create(:archived_petition, :closed, closed_at: "2018-06-30T00:00:00Z") }

    it "enqueues an Archived::AnonymizePetitionJob" do
      expect {
        petition.anonymize!("2018-12-31T00:00:00Z".in_time_zone)
      }.to have_enqueued_job(Archived::AnonymizePetitionJob)
        .with(petition, "2018-12-31T00:00:00+00:00")
        .on_queue("low_priority")
    end
  end

  describe "#anonymized?" do
    context "when anonymized_at is nil" do
      let(:petition) { FactoryBot.build(:archived_petition, :closed, anonymized_at: nil) }

      it "return false" do
        expect(petition.anonymized?).to eq(false)
      end
    end

    context "when anonymized_at is not nil" do
      let(:petition) { FactoryBot.build(:archived_petition, :closed, anonymized_at: 1.week.ago) }

      it "return true" do
        expect(petition.anonymized?).to eq(true)
      end
    end
  end

  describe "#removed?" do
    context "when petition is in a stopped state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :stopped) }

      it "returns false" do
        expect(petition.removed?).to eq(false)
      end
    end

    context "when petition is in a closed state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :closed) }

      it "returns false" do
        expect(petition.removed?).to eq(false)
      end
    end

    context "when petition is in a rejected state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :rejected) }

      it "returns false" do
        expect(petition.removed?).to eq(false)
      end
    end

    context "when petition is in a hidden state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :hidden) }

      it "returns false" do
        expect(petition.removed?).to eq(false)
      end
    end

    context "when petition is in a removed state" do
      subject(:petition) { FactoryBot.build(:archived_petition, :removed) }

      it "returns true" do
        expect(petition.removed?).to eq(true)
      end
    end
  end

  describe "#remove" do
    let(:petition) { FactoryBot.create(:archived_petition, :closed) }
    let(:current_time) { Time.current.floor }

    context "when the petition has not been removed" do
      it "returns true" do
        expect(petition.remove(current_time)).to be_truthy
      end

      it "changes the state to 'removed'" do
        expect {
          petition.remove(current_time)
        }.to change {
          petition.state
        }.from("closed").to("removed")
      end

      it "records the state at removal" do
        expect {
          petition.remove(current_time)
        }.to change {
          petition.state_at_removal
        }.from(nil).to("closed")
      end

      it "records the time of removal" do
        expect {
          petition.remove(current_time)
        }.to change {
          petition.removed_at
        }.from(nil).to(current_time)
      end
    end

    context "when the petition has already been removed" do
      let(:petition) do
        FactoryBot.create(:archived_petition, :removed,
          state_at_removal: "closed",
          removed_at: 1.hour.since(current_time)
        )
      end

      it "returns false" do
        expect(petition.remove(current_time)).to be_falsey
      end

      it "doesn't change the state at removal" do
        expect {
          petition.remove(current_time)
        }.not_to change {
          petition.state_at_removal
        }.from("closed")
      end

      it "doesn't change the time of removal" do
        expect {
          petition.remove(current_time)
        }.not_to change {
          petition.removed_at
        }.from(1.hour.since(current_time))
      end
    end
  end

  describe "#update_lock!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "doesn't update the locked_by association" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.update_lock!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "#checkout!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "updates the locked_by association" do
        expect {
          petition.checkout!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(nil).to(current_user)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "returns false" do
        expect(petition.checkout!(current_user)).to eq(false)
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.checkout!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "#force_checkout!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "updates the locked_by association" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(nil).to(current_user)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "updates the locked_by association" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(other_user).to(current_user)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to(be_within(1.second).of(Time.current))
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.force_checkout!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_at
          }.to be_within(1.second).of(Time.current)
        end
      end
    end

  describe "#release!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "doesn't update the locked_by association" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "updates the locked_by association" do
        expect {
          petition.release!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(current_user).to(nil)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.release!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_nil
      end
    end
  end
end
