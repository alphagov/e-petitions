require 'rails_helper'

RSpec.describe Domain::Log, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:domain_log)).to be_valid
  end

  describe "defaults" do
    describe "#name" do
      it "defaults to nil" do
        expect(subject.name).to be_nil
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to allow_value("localhost").for(:name) }
    it { is_expected.to allow_value("foo-bar.com").for(:name) }
    it { is_expected.not_to allow_value("foo_bar.com").for(:name) }
  end

  describe "callbacks" do
    describe "creating a domain log entry" do
      context "when the domain is an ordinary domain" do
        it "creates entries for the domain and its parents" do
          expect {
            described_class.create!(name: "example.co.uk")
          }.to change { described_class.count }.by(3)
        end
      end

      context "when the domain is a top-level domain" do
        it "only creates entries for itself" do
          expect {
            described_class.create!(name: "com")
          }.to change { described_class.count }.by(1)
        end
      end
    end
  end

  describe "scopes" do
    describe ".current" do
      let(:window) do
        [1.minute.ago.beginning_of_minute, 5.minutes]
      end

      before do
        travel_to 10.minutes.ago do
          FactoryGirl.create(:domain_log, name: "outlook.com")
        end

        travel_to 2.minutes.ago do
          FactoryGirl.create(:domain_log, name: "gmail.com")
          FactoryGirl.create(:domain_log, name: "hotmail.com")
          FactoryGirl.create(:domain_log, name: "gmail.com")
        end
      end

      it "returns logs grouped by domain name within a time window" do
        expect(described_class.current(*window).count).to match({
          "gmail.com" => 2, "hotmail.com" => 1, "com" => 3
        })
      end
    end

    describe ".stale" do
      let!(:domain_1) { FactoryGirl.create(:domain_log, created_at: 2.hours.ago) }
      let!(:domain_2) { FactoryGirl.create(:domain_log, created_at: 10.minutes.ago) }
      let!(:domain_3) { FactoryGirl.create(:domain_log, created_at: 5.minutes.ago) }

      let(:at) { 1.hour.ago }

      it "returns logs that are stale" do
        expect(described_class.stale(at)).to eq([domain_1])
      end
    end
  end
end
