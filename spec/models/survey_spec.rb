require 'rails_helper'

RSpec.describe Survey, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.create(:survey)).to be_valid
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:constituency_id]) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:constituency) }
    it { is_expected.to have_and_belong_to_many(:petitions) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:percentage_petitioners) }
    it { is_expected.to validate_presence_of(:petitions) }
  end
end
