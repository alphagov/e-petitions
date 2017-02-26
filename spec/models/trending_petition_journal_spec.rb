require "rails_helper"

RSpec.describe TrendingPetitionJournal, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:trending_petition_journal)).to be_valid
  end

  describe "defaults" do
    (0..23).each do |hour|
      it "returns 0 for the hour_#{hour}_signature_count" do
        expect(subject.public_send("hour_#{hour}_signature_count")).to eq(0)
      end
    end
  end

  describe "indexes" do
    it { is_expected.to have_db_index(:petition_id) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_presence_of(:date) }
  end
end

