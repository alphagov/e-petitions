require 'rails_helper'

RSpec.describe Archived::Petition, type: :model do
  subject(:petition){ described_class.new }

  describe "associations" do
    describe "parliament" do
      it { is_expected.to belong_to(:parliament).inverse_of(:petitions) }

      it "is required" do
        expect {
          petition.valid?
        }.to change {
          petition.errors[:parliament]
        }.from([]).to(["Parliament can't be blank"])
      end
    end
  end

  describe ".search" do
    let!(:petition_1) do
      FactoryGirl.create(:archived_petition, :closed, title: "Wombles are great", created_at: 1.year.ago, signature_count: 100)
    end

    let!(:petition_2) do
      FactoryGirl.create(:archived_petition, :closed, description: "The Wombles of Wimbledon", created_at: 2.years.ago, signature_count: 200)
    end

    it "searches based upon title" do
      expect(Archived::Petition.search(q: "Wombles")).to include(petition_1)
    end

    it "searches based upon description" do
      expect(Archived::Petition.search(q: "Wombles")).to include(petition_2)
    end

    it "sorts the results by the highest number of signatures" do
      expect(Archived::Petition.search(q: "Petition").to_a).to eq([petition_2, petition_1])
    end
  end

  describe ".by_created_at" do
    let!(:petition_1) { FactoryGirl.create(:archived_petition, created_at: 3.years.ago) }
    let!(:petition_2) { FactoryGirl.create(:archived_petition, created_at: 1.year.ago) }
    let!(:petition_3) { FactoryGirl.create(:archived_petition, created_at: 2.years.ago) }
    let(:petitions) { [petition_1, petition_3, petition_2] }

    it 'returns archived petitions ordered by the created_at timestamp' do
      expect(Archived::Petition.by_created_at).to eq(petitions)
    end
  end

  describe ".by_most_signatures" do
    let!(:petition_1) { FactoryGirl.create(:archived_petition, signature_count: 100) }
    let!(:petition_2) { FactoryGirl.create(:archived_petition, signature_count: 10) }
    let!(:petition_3) { FactoryGirl.create(:archived_petition, signature_count: 50) }
    let(:petitions) { [petition_1, petition_3, petition_2] }

    it 'returns archived petitions ordered by highest number of signatures' do
      expect(Archived::Petition.by_most_signatures).to eq(petitions)
    end
  end

  describe "#title" do
    it "defaults to nil" do
      expect(petition.title).to be_nil
    end

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(150) }
  end

  describe "#description" do
    it "defaults to nil" do
      expect(petition.description).to be_nil
    end

    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(1000) }
  end

  describe "#response" do
    it "defaults to nil" do
      expect(petition.response).to be_nil
    end
  end

  describe "#state" do
    it "defaults to 'open'" do
      expect(petition.state).to eq("open")
    end

    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_inclusion_of(:state).in_array(%w[open closed rejected]) }
  end

  describe "#reason_for_rejection" do
    it "defaults to nil" do
      expect(petition.reason_for_rejection).to be_nil
    end
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

  describe "#signature_count" do
    it "defaults to zero" do
      expect(petition.signature_count).to be_zero
    end
  end

  describe "#open?" do
    context "when petition is in an open state" do
      subject(:petition) { FactoryGirl.build(:archived_petition, :open) }

      it "returns true" do
        expect(petition.open?).to eq(true)
      end
    end

    context "when petition is in a closed state" do
      subject(:petition) { FactoryGirl.build(:archived_petition, :closed) }

      it "returns false" do
        expect(petition.open?).to eq(false)
      end
    end

    context "when petition is in a rejected state" do
      subject(:petition) { FactoryGirl.build(:archived_petition, :rejected) }

      it "returns false" do
        expect(petition.open?).to eq(false)
      end
    end
  end

  describe "#closed?" do
    context "when petition is in an open state" do
      subject(:petition) { FactoryGirl.build(:archived_petition, :open) }

      it "returns false" do
        expect(petition.closed?).to eq(false)
      end
    end

    context "when petition is in a closed state" do
      subject(:petition) { FactoryGirl.build(:archived_petition, :closed) }

      it "returns true" do
        expect(petition.closed?).to eq(true)
      end
    end

    context "when petition is in a rejected state" do
      subject(:petition) { FactoryGirl.build(:archived_petition, :rejected) }

      it "returns false" do
        expect(petition.closed?).to eq(false)
      end
    end
  end

  describe "#rejected?" do
    context "when petition is in an open state" do
      subject(:petition) { FactoryGirl.build(:archived_petition, :open) }

      it "returns false" do
        expect(petition.rejected?).to eq(false)
      end
    end

    context "when petition is in a closed state" do
      subject(:petition) { FactoryGirl.build(:archived_petition, :closed) }

      it "returns false" do
        expect(petition.rejected?).to eq(false)
      end
    end

    context "when petition is in a rejected state" do
      subject(:petition) { FactoryGirl.build(:archived_petition, :rejected) }

      it "returns true" do
        expect(petition.rejected?).to eq(true)
      end
    end
  end

  describe "#duration" do
    context "when the parliament petition duration is nil" do
      let(:parliament) { FactoryGirl.create(:parliament, petition_duration: nil) }

      context "and the petition was not published" do
        let(:petition) { FactoryGirl.create(:archived_petition, :rejected, parliament: parliament) }

        it "returns 0" do
          expect(petition.duration).to eq(0)
        end
      end

      context "and the petition was published for three months" do
        let(:opened_at) { 2.years.ago }
        let(:closed_at) { opened_at + 3.months }
        let(:petition) { FactoryGirl.create(:archived_petition, opened_at: opened_at, closed_at: closed_at, parliament: parliament) }

        it "returns 3" do
          expect(petition.duration).to eq(3)
        end
      end

      context "and the petition was published for six months" do
        let(:opened_at) { 2.years.ago }
        let(:closed_at) { opened_at + 6.months }
        let(:petition) { FactoryGirl.create(:archived_petition, opened_at: opened_at, closed_at: closed_at, parliament: parliament) }

        it "returns 3" do
          expect(petition.duration).to eq(6)
        end
      end

      context "and the petition was published for nine months" do
        let(:opened_at) { 2.years.ago }
        let(:closed_at) { opened_at + 9.months }
        let(:petition) { FactoryGirl.create(:archived_petition, opened_at: opened_at, closed_at: closed_at, parliament: parliament) }

        it "returns 3" do
          expect(petition.duration).to eq(9)
        end
      end

      context "and the petition was published for twelve months" do
        let(:opened_at) { 2.years.ago }
        let(:closed_at) { opened_at + 12.months }
        let(:petition) { FactoryGirl.create(:archived_petition, opened_at: opened_at, closed_at: closed_at, parliament: parliament) }

        it "returns 3" do
          expect(petition.duration).to eq(12)
        end
      end

      context "and the petition was published for an arbitrary length of time" do
        let(:opened_at) { 2.years.ago }
        let(:closed_at) { opened_at + 45.days }
        let(:petition) { FactoryGirl.create(:archived_petition, opened_at: opened_at, closed_at: closed_at, parliament: parliament) }

        it "returns a fractional number of months assuming that 1 month == 30 days" do
          expect(petition.duration).to eq(1.5)
        end
      end
    end

    context "when the parliament petition duration is not nil" do
      let(:parliament) { FactoryGirl.create(:parliament, petition_duration: 6) }
      let(:petition) { FactoryGirl.create(:archived_petition, parliament: parliament) }

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
    let(:parliament) { FactoryGirl.create(:parliament, :dissolved, :archived, dissolution_at: "2015-05-18T23:59:59") }
    let(:petition) { FactoryGirl.create(:archived_petition, parliament: parliament, closed_at: closed_at) }

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
    let(:parliament) { FactoryGirl.create(:parliament, threshold_for_response: 500) }
    let(:petition) { FactoryGirl.create(:archived_petition, parliament: parliament, signature_count: signature_count) }

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
    let(:parliament) { FactoryGirl.create(:parliament, threshold_for_debate: 5000) }
    let(:petition) { FactoryGirl.create(:archived_petition, parliament: parliament, signature_count: signature_count) }

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
end
