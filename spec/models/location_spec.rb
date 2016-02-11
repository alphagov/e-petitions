require 'rails_helper'

RSpec.describe Location, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:location)).to be_valid
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:code]).unique }
    it { is_expected.to have_db_index([:name]).unique }
    it { is_expected.to have_db_index([:start_date, :end_date]) }
  end

  describe "validations" do
    subject { FactoryGirl.build(:location) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_length_of(:code).is_at_most(30) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
  end

  describe ".current" do
    let!(:ussr) { FactoryGirl.create(:location, code: "SU", name: "USSR", end_date: "1991-12-25") }
    let!(:uk) { FactoryGirl.create(:location, code: "GB", name: "United Kingdom") }
    let!(:russia) { FactoryGirl.create(:location, code: "RU", name: "Russia", start_date: "1991-12-25") }

    subject { described_class.current.to_a }

    it "includes countries with no start or end date" do
      expect(subject).to include(uk)
    end

    it "includes countries with an start date in the past" do
      travel_to "1997-07-01" do
        expect(subject).to include(russia)
      end
    end

    it "excludes countries with an start date in the future" do
      travel_to "1989-11-09" do
        expect(subject).not_to include(russia)
      end
    end

    it "excludes countries with an end date in the past" do
      travel_to "1997-07-01" do
        expect(subject).not_to include(ussr)
      end
    end

    it "includes countries with an end date in the future" do
      travel_to "1989-11-09" do
        expect(subject).to include(ussr)
      end
    end

    it "includes the new country on the date of transition" do
      travel_to "1991-12-25" do
        expect(subject).to include(russia)
      end
    end

    it "excludes the old country on the date of transition" do
      travel_to "1991-12-25" do
        expect(subject).not_to include(ussr)
      end
    end

    it "is sorted by name" do
      expect(subject).to eq([russia, uk])
    end
  end

  describe ".menu" do
    let!(:russia) { FactoryGirl.create(:location, code: "RU", name: "Russia", start_date: "1991-12-25") }
    let!(:uk) { FactoryGirl.create(:location, code: "GB", name: "United Kingdom") }
    let!(:australia) { FactoryGirl.create(:location, code: "AU", name: "Australia") }

    subject { described_class.menu }

    it "returns a sorted list of locations" do
      expect(subject).to eq([["Australia", "AU"], ["Russia", "RU"], ["United Kingdom", "GB"]])
    end
  end
end
