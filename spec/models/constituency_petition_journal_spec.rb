require 'rails_helper'

RSpec.describe ConstituencyPetitionJournal, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:constituency_petition_journal)).to be_valid
  end

  context "defaults" do
    subject { described_class.new }
    it "has 0 for initial signature_count" do
      expect(subject.signature_count).to eq 0
    end
  end

  context "validations" do
    subject { FactoryGirl.build(:constituency_petition_journal) }

    it { is_expected.to validate_presence_of(:constituency_id) }
    it { is_expected.to validate_length_of(:constituency_id).is_at_most(255) }
    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_uniqueness_of(:petition_id).scoped_to(:constituency_id) }
    it { is_expected.to validate_presence_of(:signature_count) }
  end
end
