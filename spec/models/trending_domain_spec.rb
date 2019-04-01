require 'rails_helper'

RSpec.describe TrendingDomain, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:trending_domain)).to be_valid
  end

  describe "read-only attributes" do
    it { is_expected.to have_readonly_attribute(:domain) }
    it { is_expected.to have_readonly_attribute(:count) }
    it { is_expected.to have_readonly_attribute(:starts_at) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:domain) }
    it { is_expected.to validate_length_of(:domain).is_at_most(100) }
    it { is_expected.to validate_presence_of(:count) }
    it { is_expected.to validate_numericality_of(:count).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:starts_at) }
  end

  describe ".log!" do
    let(:petition) { FactoryBot.create(:open_petition) }

    it "creates a trending domain entry" do
      trending_domain = petition.trending_domains.log!("2019-03-31T16:00:00Z", "example.com", 32)

      expect(trending_domain.petition).to eq(petition)
      expect(trending_domain.domain).to eq("example.com")
      expect(trending_domain.starts_at).to eq(Time.utc(2019, 3, 31, 16, 0, 0))
      expect(trending_domain.count).to eq(32)
    end
  end

  describe "#ends_at" do
    let(:starts_at) { Time.utc(2019, 3, 31, 16, 0, 0) }
    let(:trending_domain) { FactoryBot.build(:trending_domain, starts_at: starts_at) }

    it "is 1 hour later than starts_at" do
      expect(trending_domain.ends_at).to eq(Time.utc(2019, 3, 31, 17, 0, 0))
    end
  end
end
