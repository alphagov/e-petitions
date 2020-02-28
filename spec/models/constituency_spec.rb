require 'rails_helper'

RSpec.describe Constituency, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:constituency)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:id).of_type(:string).with_options(null: false, limit: 9, primary_key: true) }
    it { is_expected.to have_db_column(:region_id).of_type(:string).with_options(null: false, limit: 9) }
    it { is_expected.to have_db_column(:name_en).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:name_cy).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:example_postcode).of_type(:string).with_options(null: false, limit: 7) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:region) }
    it { is_expected.to have_one(:member) }
    it { is_expected.to have_many(:postcodes) }
    it { is_expected.to have_many(:signatures) }
    it { is_expected.to have_many(:petitions).through(:signatures) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:region_id]) }
    it { is_expected.to have_db_index([:name_en]).unique }
    it { is_expected.to have_db_index([:name_cy]).unique }
  end
end
