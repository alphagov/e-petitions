require 'rails_helper'

RSpec.describe DebateOutcome, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:debate_outcome)).to be_valid
  end

  describe 'petition' do
    it { is_expected.to belong_to(:petition).touch(true) }
  end

  context "validations" do
    subject { FactoryGirl.build(:debate_outcome) }

    it { is_expected.to validate_presence_of(:debated_on) }

    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_uniqueness_of(:petition_id) }

    it { is_expected.to validate_length_of(:transcript_url).is_at_most(500) }
    it { is_expected.to validate_length_of(:video_url).is_at_most(500) }
  end
end
