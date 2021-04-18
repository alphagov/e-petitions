require 'rails_helper'

RSpec.describe Feedback, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:feedback)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:comment).of_type(:string).with_options(limit: 32768, null: false) }
    it { is_expected.to have_db_column(:petition_link_or_title).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:user_agent).of_type(:string) }
    it { is_expected.to have_db_column(:ip_address).of_type(:string).with_options(limit: 40) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
  end

  describe "validations" do
    it "is invalid by default" do
      expect(subject).not_to be_valid
    end

    it { is_expected.to validate_presence_of(:comment) }
    it { is_expected.to validate_length_of(:comment).is_at_most(32768) }
    it { is_expected.to validate_length_of(:petition_link_or_title).is_at_most(255) }
    it { is_expected.to validate_length_of(:email).is_at_most(255) }
    it { is_expected.to allow_value("foo@example.com").for(:email) }
    it { is_expected.not_to allow_value("foo@example").for(:email) }
    it { is_expected.not_to allow_value("foo").for(:email) }
  end
end
