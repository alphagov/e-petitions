require 'rails_helper'

RSpec.describe DebateOutcome, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:debate_outcome)).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition).touch(true) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id]).unique }
    it { is_expected.to have_db_index([:petition_id, :debated_on]) }
  end

  describe "validations" do
    subject { FactoryGirl.build(:debate_outcome) }

    it { is_expected.to validate_presence_of(:debated_on) }
    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_length_of(:transcript_url).is_at_most(500) }
    it { is_expected.to validate_length_of(:video_url).is_at_most(500) }
  end

  describe "callbacks" do
    describe "when the debate outcome is created" do
      let(:petition) { FactoryGirl.create(:awaiting_debate_petition) }
      let(:debate_outcome) { FactoryGirl.build(:debate_outcome, petition: petition) }
      let(:now) { Time.current }

      it "updates the debate_outcome_at timestamp" do
        expect {
          debate_outcome.save!
        }.to change {
          petition.reload.debate_outcome_at
        }.from(nil).to(be_within(1.second).of(now))
      end
    end
  end
end
