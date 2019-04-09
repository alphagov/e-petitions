require 'rails_helper'

RSpec.describe TrendingIp, type: :model do
  let(:geoip_db_path) { "/path/to/GeoLite2-Country.mmdb" }
  let(:geoip_db) { double(:geoip_db) }
  let(:geoip_result) { double(:geoip_result) }
  let(:geoip_country) { double(:geoip_country) }

  before do
    allow(MaxMindDB).to receive(:new).with(geoip_db_path).and_return(geoip_db)
    allow(geoip_db).to receive(:lookup).and_return(geoip_result)
    allow(geoip_result).to receive(:found?).and_return(true)
    allow(geoip_result).to receive(:country).and_return(geoip_country)
    allow(geoip_country).to receive(:iso_code).and_return("GB")
  end

  it "has a valid factory" do
    expect(FactoryBot.build(:trending_ip)).to be_valid
  end

  describe "read-only attributes" do
    it { is_expected.to have_readonly_attribute(:ip_address) }
    it { is_expected.to have_readonly_attribute(:country_code) }
    it { is_expected.to have_readonly_attribute(:count) }
    it { is_expected.to have_readonly_attribute(:starts_at) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:ip_address) }
    it { is_expected.to validate_presence_of(:count) }
    it { is_expected.to validate_numericality_of(:count).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:starts_at) }
  end

  describe ".log!" do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:geoip_db_path) { "/path/to/GeoLite2-Country.mmdb" }
    let(:geoip_db) { double(:geoip_db) }
    let(:geoip_result) { double(:geoip_result) }
    let(:geoip_country) { double(:geoip_country) }

    before do
      allow(MaxMindDB).to receive(:new).with(geoip_db_path).and_return(geoip_db)
      allow(geoip_db).to receive(:lookup).with("127.0.0.1").and_return(geoip_result)
      allow(geoip_result).to receive(:found?).and_return(true)
      allow(geoip_result).to receive(:country).and_return(geoip_country)
      allow(geoip_country).to receive(:iso_code).and_return("GB")
    end

    it "creates a trending ip entry" do
      trending_ip = petition.trending_ips.log!("2019-03-31T16:00:00Z", "127.0.0.1", 32)

      expect(trending_ip.petition).to eq(petition)
      expect(trending_ip.ip_address).to eq("127.0.0.1")
      expect(trending_ip.country_code).to eq("GB")
      expect(trending_ip.starts_at).to eq(Time.utc(2019, 3, 31, 16, 0, 0))
      expect(trending_ip.count).to eq(32)
    end
  end

  describe "#ends_at" do
    let(:starts_at) { Time.utc(2019, 3, 31, 16, 0, 0) }
    let(:trending_ip) { FactoryBot.build(:trending_ip, starts_at: starts_at) }

    it "is 1 hour later than starts_at" do
      expect(trending_ip.ends_at).to eq(Time.utc(2019, 3, 31, 17, 0, 0))
    end
  end

  describe "#window" do
    let(:starts_at) { Time.utc(2019, 3, 31, 16, 0, 0) }
    let(:trending_ip) { FactoryBot.build(:trending_ip, starts_at: starts_at) }

    it "returns a ISO8601 UTC timestamp" do
      expect(trending_ip.window).to eq("2019-03-31T16:00:00Z")
    end
  end
end
