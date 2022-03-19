require 'rails_helper'

RSpec.describe Petition::Email, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:petition_email)).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id]) }
  end

  describe "validations" do
    subject { FactoryBot.build(:petition_email) }

    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_length_of(:subject).is_at_most(150) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(6000) }
  end
end
