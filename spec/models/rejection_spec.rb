require 'rails_helper'

RSpec.describe Rejection, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:rejection)).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition).touch(true) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id]).unique }
  end

  describe "validations" do
    subject { FactoryBot.build(:rejection) }

    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_inclusion_of(:code).in_array(Rejection::CODES) }
    it { is_expected.to validate_length_of(:details_en).is_at_most(4000) }
    it { is_expected.to validate_length_of(:details_cy).is_at_most(4000) }
  end

  describe "callbacks" do
    describe "when the rejection is created" do
      let(:petition) { FactoryBot.create(:validated_petition) }
      let(:rejection) { FactoryBot.build(:rejection, code: rejection_code, petition: petition) }
      let(:now) { Time.current }

      context "and the rejection should be public" do
        let(:rejection_code) { "duplicate" }

        it "changes the state of the petition to be rejected" do
          expect {
            rejection.save!
          }.to change {
            petition.reload.state
          }.from(Petition::VALIDATED_STATE).to(Petition::REJECTED_STATE)
        end

        it "updates the rejected_at timestamp" do
          expect {
            rejection.save!
          }.to change {
            petition.reload.rejected_at
          }.from(nil).to(be_within(1.second).of(now))
        end
      end

      context "and the petition must be hidden" do
        let(:rejection_code) { "offensive" }

        it "changes the state of the petition to hidden" do
          expect {
            rejection.save!
          }.to change {
            petition.reload.state
          }.from(Petition::VALIDATED_STATE).to(Petition::HIDDEN_STATE)
        end

        it "updates the rejected_at timestamp" do
          expect {
            rejection.save!
          }.to change {
            petition.reload.rejected_at
          }.from(nil).to(be_within(1.second).of(now))
        end
      end
    end
  end

  describe "#hide_petition?" do
    Rejection::HIDDEN_CODES.each do |code|
      context "when the rejection code is #{code}" do
        let(:rejection) { described_class.new(code: code) }

        it "returns true" do
          expect(rejection.hide_petition?).to eq(true)
        end
      end
    end

    (Rejection::CODES - Rejection::HIDDEN_CODES).each do |code|
      context "when the rejection code is #{code}" do
        let(:rejection) { described_class.new(code: code) }

        it "returns false" do
          expect(rejection.hide_petition?).to eq(false)
        end
      end
    end
  end

  describe "#state_for_petition" do
    Rejection::HIDDEN_CODES.each do |code|
      context "when the rejection code is #{code}" do
        let(:rejection) { described_class.new(code: code) }

        it "returns Petition::HIDDEN_STATE" do
          expect(rejection.state_for_petition).to eq(Petition::HIDDEN_STATE)
        end
      end
    end

    (Rejection::CODES - Rejection::HIDDEN_CODES).each do |code|
      context "when the rejection code is #{code}" do
        let(:rejection) { described_class.new(code: code) }

        it "returns Petition::REJECTED_STATE" do
          expect(rejection.state_for_petition).to eq(Petition::REJECTED_STATE)
        end
      end
    end
  end
end
