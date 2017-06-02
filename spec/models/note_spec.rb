require 'rails_helper'

RSpec.describe Note, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:note)).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition).touch(true) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id]).unique }
  end

  describe "validations" do
    subject { FactoryGirl.build(:note) }

    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.not_to validate_presence_of(:details) }
  end
end
