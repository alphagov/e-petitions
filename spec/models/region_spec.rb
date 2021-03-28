require 'rails_helper'

RSpec.describe Region, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:region)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:id).of_type(:string).with_options(null: false, limit: 9, primary: true) }
    it { is_expected.to have_db_column(:name_en).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:name_cy).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "associations" do
    it { is_expected.to have_many(:constituencies) }
    it { is_expected.to have_many(:members) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:name_en]).unique }
    it { is_expected.to have_db_index([:name_cy]).unique }
  end
end
