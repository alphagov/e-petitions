require 'rails_helper'

RSpec.describe Postcode, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:region)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:id).of_type(:string).with_options(null: false, limit: 7, primary: true) }
    it { is_expected.to have_db_column(:constituency_id).of_type(:string).with_options(null: false, limit: 9) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:constituency) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:constituency_id]) }
  end
end
