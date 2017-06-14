require 'rails_helper'

RSpec.describe Archived::Note, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:archived_note)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:petition_id).of_type(:integer) }
    it { is_expected.to have_db_column(:details).of_type(:text) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition).touch(true) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id]).unique }
  end

  describe "validations" do
    subject { FactoryGirl.build(:archived_note) }

    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.not_to validate_presence_of(:details) }
  end
end
