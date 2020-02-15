require 'rails_helper'

RSpec.describe Region, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:region)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:external_id).of_type(:string).with_options(null: false, limit: 30) }
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 50) }
    it { is_expected.to have_db_column(:ons_code).of_type(:string).with_options(null: false, limit: 10) }
  end

  describe "associations" do
    it { is_expected.to have_many(:constituencies) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:external_id]).unique }
    it { is_expected.to have_db_index([:name]).unique }
  end

  describe "validations" do
    subject { FactoryBot.build(:region) }

    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_length_of(:external_id).is_at_most(30) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(50) }

    it { is_expected.to validate_presence_of(:ons_code) }
    it { is_expected.to validate_length_of(:ons_code).is_at_most(10) }
  end
end
