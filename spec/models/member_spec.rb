require 'rails_helper'

RSpec.describe Member, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:member)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:id).of_type(:integer).with_options(null: false, primary_key: true) }
    it { is_expected.to have_db_column(:region_id).of_type(:string).with_options(null: true, limit: 9) }
    it { is_expected.to have_db_column(:constituency_id).of_type(:string).with_options(null: true, limit: 9) }
    it { is_expected.to have_db_column(:name_en).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:name_cy).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:party_en).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:party_cy).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:region).optional }
    it { is_expected.to belong_to(:constituency).optional }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:region_id]) }
    it { is_expected.to have_db_index([:constituency_id]).unique }
  end
end
