require 'rails_helper'

RSpec.describe RateLimit, type: :model do
  subject { described_class.create! }

  describe "validations" do
    it { is_expected.to validate_presence_of(:burst_rate) }
    it { is_expected.to validate_numericality_of(:burst_rate).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:burst_period) }
    it { is_expected.to validate_numericality_of(:burst_period).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:sustained_rate) }
    it { is_expected.to validate_numericality_of(:sustained_rate).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:sustained_period) }
    it { is_expected.to validate_numericality_of(:sustained_period).only_integer.is_greater_than(0) }
    it { is_expected.to validate_length_of(:domain_whitelist).is_at_most(10000) }
    it { is_expected.to validate_length_of(:ip_whitelist).is_at_most(10000) }
    it { is_expected.to validate_length_of(:domain_blacklist).is_at_most(50000) }
    it { is_expected.to validate_length_of(:ip_blacklist).is_at_most(50000) }
    it { is_expected.to validate_length_of(:countries).is_at_most(2000) }

    context "when the sustained rate is less than the burst rate" do
      before do
        subject.update(sustained_rate: 10, burst_rate: 20)
      end

      it "adds an error message" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors[:sustained_rate]).to include("Sustained rate must be greater than burst rate")
      end
    end

    context "when the sustained period is less than the burst period" do
      before do
        subject.update(sustained_period: 30, burst_period: 60)
      end

      it "adds an error message" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors[:sustained_period]).to include("Sustained period must be greater than burst period")
      end
    end

    context "when the domain whitelist is invalid" do
      before do
        subject.update(domain_whitelist: "(foo")
      end

      it "adds an error message" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors[:domain_whitelist]).to include("Domain whitelist is invalid")
      end
    end

    context "when the IP whitelist is invalid" do
      before do
        subject.update(ip_whitelist: "foo")
      end

      it "adds an error message" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors[:ip_whitelist]).to include("IP whitelist is invalid")
      end
    end

    context "when the domain blacklist is invalid" do
      before do
        subject.update(domain_blacklist: "(foo")
      end

      it "adds an error message" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors[:domain_blacklist]).to include("Domain blacklist is invalid")
      end
    end

    context "when the IP blacklist is invalid" do
      before do
        subject.update(ip_blacklist: "foo")
      end

      it "adds an error message" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors[:ip_blacklist]).to include("IP blacklist is invalid")
      end
    end
  end

  describe "#exceeded?" do
    let(:petition) { FactoryGirl.create(:open_petition) }
    let(:signature) { FactoryGirl.create(:pending_signature, petition: petition) }

    let(:domain_whitelist) { "" }
    let(:ip_whitelist) { "" }

    let(:domain_blacklist) { "" }
    let(:ip_blacklist) { "" }

    let(:countries) { "" }
    let(:geoblocking_enabled) { false }

    subject do
      described_class.create!(
        burst_rate: 10, burst_period: 60,
        sustained_rate: 20, sustained_period: 300,
        domain_whitelist: domain_whitelist, ip_whitelist: ip_whitelist,
        domain_blacklist: domain_blacklist, ip_blacklist: ip_blacklist,
        countries: countries, geoblocking_enabled: geoblocking_enabled
      )
    end

    shared_examples_for "domain whitelisting" do
      let(:domain_whitelist) { "foo.com\n*.bar.com\n**.baz.com\n" }

      it "returns true when the domain is not whitelisted" do
        allow(signature).to receive(:domain).and_return("example.com")
        expect(subject.exceeded?(signature)).to eq(true)
      end

      it "returns false when the domain is whitelisted" do
        allow(signature).to receive(:domain).and_return("foo.com")
        expect(subject.exceeded?(signature)).to eq(false)
      end

      it "returns false when the domain is whitelisted by a grep pattern" do
        allow(signature).to receive(:domain).and_return("foo.bar.com")
        expect(subject.exceeded?(signature)).to eq(false)
      end

      it "returns false when the domain is whitelisted by a recursive grep pattern" do
        allow(signature).to receive(:domain).and_return("foo.bar.baz.com")
        expect(subject.exceeded?(signature)).to eq(false)
      end
    end

    shared_examples_for "domain blacklisting" do
      let(:domain_blacklist) { "foo.com\n*.bar.com\n**.baz.com\n" }

      it "returns false when the domain is not blacklisted" do
        allow(signature).to receive(:domain).and_return("example.com")
        expect(subject.exceeded?(signature)).to eq(false)
      end

      it "returns true when the domain is blacklisted" do
        allow(signature).to receive(:domain).and_return("foo.com")
        expect(subject.exceeded?(signature)).to eq(true)
      end

      it "returns true when the domain is blacklisted by a grep pattern" do
        allow(signature).to receive(:domain).and_return("foo.bar.com")
        expect(subject.exceeded?(signature)).to eq(true)
      end

      it "returns true when the domain is blacklisted by a recursive grep pattern" do
        allow(signature).to receive(:domain).and_return("foo.bar.baz.com")
        expect(subject.exceeded?(signature)).to eq(true)
      end
    end

    shared_examples_for "IP whitelisting" do
      let(:ip_whitelist) { "10.0.1.1\n10.0.1.2/32\n10.0.2.0/28\n" }

      it "returns true when the IP address is not whitelisted" do
        allow(signature).to receive(:ip_address).and_return("10.1.1.1")
        expect(subject.exceeded?(signature)).to eq(true)
      end

      it "returns false when the IP address is whitelisted" do
        allow(signature).to receive(:ip_address).and_return("10.0.1.1")
        expect(subject.exceeded?(signature)).to eq(false)
      end

      it "returns false when the IP address is whitelisted by a CIDR address" do
        allow(signature).to receive(:ip_address).and_return("10.0.1.2")
        expect(subject.exceeded?(signature)).to eq(false)
      end

      it "returns false when the IP address is whitelisted by a CIDR range" do
        allow(signature).to receive(:ip_address).and_return("10.0.2.7")
        expect(subject.exceeded?(signature)).to eq(false)
      end
    end

    shared_examples_for "IP blacklisting" do
      let(:ip_blacklist) { "10.0.1.1\n10.0.1.2/32\n10.0.2.0/28\n" }

      it "returns false when the IP address is not blacklisted" do
        allow(signature).to receive(:ip_address).and_return("10.1.1.1")
        expect(subject.exceeded?(signature)).to eq(false)
      end

      it "returns true when the IP address is blacklisted" do
        allow(signature).to receive(:ip_address).and_return("10.0.1.1")
        expect(subject.exceeded?(signature)).to eq(true)
      end

      it "returns true when the IP address is blacklisted by a CIDR address" do
        allow(signature).to receive(:ip_address).and_return("10.0.1.2")
        expect(subject.exceeded?(signature)).to eq(true)
      end

      it "returns true when the IP address is blacklisted by a CIDR range" do
        allow(signature).to receive(:ip_address).and_return("10.0.2.7")
        expect(subject.exceeded?(signature)).to eq(true)
      end
    end

    shared_examples_for "GeoIP blocking" do
      let(:geoblocking_enabled) { true }
      let(:countries) { "United Kingdom" }
      let(:geoip_db_path) { "/path/to/GeoLite2-Country.mmdb" }
      let(:geoip_db) { double(:geoip_db) }
      let(:geoip_result) { double(:geoip_result) }
      let(:country) { double(:country) }

      before do
        allow(MaxMindDB).to receive(:new).with(geoip_db_path).and_return(geoip_db)
        allow(geoip_db).to receive(:lookup).with("12.34.56.78").and_return(geoip_result)
        allow(signature).to receive(:ip_address).and_return("12.34.56.78")
        allow(geoip_result).to receive(:found?).and_return(true)
        allow(geoip_result).to receive(:country).and_return(country)
      end

      it "returns false when the country is allowed" do
        allow(country).to receive(:name).and_return("United Kingdom")
        expect(subject.exceeded?(signature)).to eq(false)
      end

      it "returns true when the country is not allowed" do
        allow(country).to receive(:name).and_return("Neverland")
        expect(subject.exceeded?(signature)).to eq(true)
      end

      it "returns true when a result is not found" do
        allow(geoip_result).to receive(:found?).and_return(false)
        expect(subject.exceeded?(signature)).to eq(true)
      end
    end

    context "when both rates are below the threshold" do
      before do
        allow(signature).to receive(:rate).with(60).and_return(5)
        allow(signature).to receive(:rate).with(300).and_return(10)
      end

      it "returns false" do
        expect(subject.exceeded?(signature)).to eq(false)
      end

      it_behaves_like "domain blacklisting"
      it_behaves_like "IP blacklisting"
      it_behaves_like "GeoIP blocking"
    end

    context "when the burst rate is above the threshold" do
      before do
        allow(signature).to receive(:rate).with(60).and_return(15)
        allow(signature).to receive(:rate).with(300).and_return(10)
      end

      it "returns true" do
        expect(subject.exceeded?(signature)).to eq(true)
      end

      it_behaves_like "domain whitelisting"
      it_behaves_like "IP whitelisting"
    end

    context "when the sustained rate is above the threshold" do
      before do
        allow(signature).to receive(:rate).with(60).and_return(5)
        allow(signature).to receive(:rate).with(300).and_return(30)
      end

      it "returns true" do
        expect(subject.exceeded?(signature)).to eq(true)
      end

      it_behaves_like "domain whitelisting"
      it_behaves_like "IP whitelisting"
    end

    context "when both rates are above the threshold" do
      before do
        allow(signature).to receive(:rate).with(60).and_return(15)
        allow(signature).to receive(:rate).with(300).and_return(30)
      end

      it "returns true" do
        expect(subject.exceeded?(signature)).to eq(true)
      end

      it_behaves_like "domain whitelisting"
      it_behaves_like "IP whitelisting"
    end
  end

  describe "#domain_whitelist=" do
    subject do
      described_class.new(domain_whitelist: " foo.com\r\nbar.com\r\n")
    end

    it "normalizes line endings and strips whitespace" do
      expect(subject.domain_whitelist).to eq("foo.com\nbar.com")
    end
  end

  describe "#ip_whitelist=" do
    subject do
      described_class.new(ip_whitelist: " 192.168.1.1\r\n10.0.1.1/32\r\n")
    end

    it "normalizes line endings and strips whitespace" do
      expect(subject.ip_whitelist).to eq("192.168.1.1\n10.0.1.1/32")
    end
  end

  describe "#domain_blacklist=" do
    subject do
      described_class.new(domain_blacklist: " foo.com\r\nbar.com\r\n")
    end

    it "normalizes line endings and strips whitespace" do
      expect(subject.domain_blacklist).to eq("foo.com\nbar.com")
    end
  end

  describe "#ip_blacklist=" do
    subject do
      described_class.new(ip_blacklist: " 192.168.1.1\r\n10.0.1.1/32\r\n")
    end

    it "normalizes line endings and strips whitespace" do
      expect(subject.ip_blacklist).to eq("192.168.1.1\n10.0.1.1/32")
    end
  end

  describe "#countries=" do
    subject do
      described_class.new(countries: " United Kingdom\r\nIreland\r\n")
    end

    it "normalizes line endings and strips whitespace" do
      expect(subject.countries).to eq("United Kingdom\nIreland")
    end
  end

  describe "#whitelisted_domains" do
    subject do
      described_class.create!(domain_whitelist: domain_whitelist)
    end

    context "when there is extra whitespace" do
      let :domain_whitelist do
        <<-EOF
          foo.com
             bar.com

        EOF
      end

      it "is is stripped" do
        expect(subject.whitelisted_domains).to eq([/\Afoo.com\z/, /\Abar.com\z/])
      end
    end

    context "when there are blank lines" do
      let :domain_whitelist do
        <<-EOF
          foo.com

             bar.com

        EOF
      end

      it "they are stripped" do
        expect(subject.whitelisted_domains).to eq([/\Afoo.com\z/, /\Abar.com\z/])
      end
    end

    context "when there are line comments" do
      let :domain_whitelist do
        <<-EOF
          # This is a test
          foo.com

             bar.com

        EOF
      end

      it "they are stripped" do
        expect(subject.whitelisted_domains).to eq([/\Afoo.com\z/, /\Abar.com\z/])
      end
    end

    context "when there are inline comments" do
      let :domain_whitelist do
        <<-EOF
          foo.com # This is a test

             bar.com

        EOF
      end

      it "they are stripped" do
        expect(subject.whitelisted_domains).to eq([/\Afoo.com\z/, /\Abar.com\z/])
      end
    end
  end

  describe "#whitelisted_ips" do
    subject do
      described_class.create!(ip_whitelist: ip_whitelist)
    end

    let(:ip_addr_1) { IPAddr.new("10.0.1.1") }
    let(:ip_addr_2) { IPAddr.new("192.168.1.0/24") }

    context "when there is extra whitespace" do
      let :ip_whitelist do
        <<-EOF
          10.0.1.1
             192.168.1.0/24

        EOF
      end

      it "is is stripped" do
        expect(subject.whitelisted_ips).to eq([ip_addr_1, ip_addr_2])
      end
    end

    context "when there are blank lines" do
      let :ip_whitelist do
        <<-EOF
          10.0.1.1

             192.168.1.0/24

        EOF
      end

      it "they are stripped" do
        expect(subject.whitelisted_ips).to eq([ip_addr_1, ip_addr_2])
      end
    end

    context "when there are line comments" do
      let :ip_whitelist do
        <<-EOF
          # This is a test
          10.0.1.1

             192.168.1.0/24

        EOF
      end

      it "they are stripped" do
        expect(subject.whitelisted_ips).to eq([ip_addr_1, ip_addr_2])
      end
    end

    context "when there are inline comments" do
      let :ip_whitelist do
        <<-EOF
          10.0.1.1 # This is a test

             192.168.1.0/24

        EOF
      end

      it "they are stripped" do
        expect(subject.whitelisted_ips).to eq([ip_addr_1, ip_addr_2])
      end
    end
  end

  describe "#blacklisted_domains" do
    subject do
      described_class.create!(domain_blacklist: domain_blacklist)
    end

    context "when there is extra whitespace" do
      let :domain_blacklist do
        <<-EOF
          foo.com
             bar.com

        EOF
      end

      it "is is stripped" do
        expect(subject.blacklisted_domains).to eq([/\Afoo.com\z/, /\Abar.com\z/])
      end
    end

    context "when there are blank lines" do
      let :domain_blacklist do
        <<-EOF
          foo.com

             bar.com

        EOF
      end

      it "they are stripped" do
        expect(subject.blacklisted_domains).to eq([/\Afoo.com\z/, /\Abar.com\z/])
      end
    end

    context "when there are line comments" do
      let :domain_blacklist do
        <<-EOF
          # This is a test
          foo.com

             bar.com

        EOF
      end

      it "they are stripped" do
        expect(subject.blacklisted_domains).to eq([/\Afoo.com\z/, /\Abar.com\z/])
      end
    end

    context "when there are inline comments" do
      let :domain_blacklist do
        <<-EOF
          foo.com # This is a test

             bar.com

        EOF
      end

      it "they are stripped" do
        expect(subject.blacklisted_domains).to eq([/\Afoo.com\z/, /\Abar.com\z/])
      end
    end
  end

  describe "#blacklisted_ips" do
    subject do
      described_class.create!(ip_blacklist: ip_blacklist)
    end

    let(:ip_addr_1) { IPAddr.new("10.0.1.1") }
    let(:ip_addr_2) { IPAddr.new("192.168.1.0/24") }

    context "when there is extra whitespace" do
      let :ip_blacklist do
        <<-EOF
          10.0.1.1
             192.168.1.0/24

        EOF
      end

      it "is is stripped" do
        expect(subject.blacklisted_ips).to eq([ip_addr_1, ip_addr_2])
      end
    end

    context "when there are blank lines" do
      let :ip_blacklist do
        <<-EOF
          10.0.1.1

             192.168.1.0/24

        EOF
      end

      it "they are stripped" do
        expect(subject.blacklisted_ips).to eq([ip_addr_1, ip_addr_2])
      end
    end

    context "when there are line comments" do
      let :ip_blacklist do
        <<-EOF
          # This is a test
          10.0.1.1

             192.168.1.0/24

        EOF
      end

      it "they are stripped" do
        expect(subject.blacklisted_ips).to eq([ip_addr_1, ip_addr_2])
      end
    end

    context "when there are inline comments" do
      let :ip_blacklist do
        <<-EOF
          10.0.1.1 # This is a test

             192.168.1.0/24

        EOF
      end

      it "they are stripped" do
        expect(subject.blacklisted_ips).to eq([ip_addr_1, ip_addr_2])
      end
    end
  end

  describe "#allowed_countries" do
    subject do
      described_class.create!(countries: countries)
    end

    let(:country_1) { "United Kingdom" }
    let(:country_2) { "Ireland" }

    context "when there is extra whitespace" do
      let :countries do
        <<-EOF
          United Kingdom
             Ireland

        EOF
      end

      it "is is stripped" do
        expect(subject.allowed_countries).to eq([country_1, country_2])
      end
    end

    context "when there are blank lines" do
      let :countries do
        <<-EOF
          United Kingdom

             Ireland

        EOF
      end

      it "they are stripped" do
        expect(subject.allowed_countries).to eq([country_1, country_2])
      end
    end

    context "when there are line comments" do
      let :countries do
        <<-EOF
          # This is a test
          United Kingdom

             Ireland

        EOF
      end

      it "they are stripped" do
        expect(subject.allowed_countries).to eq([country_1, country_2])
      end
    end

    context "when there are inline comments" do
      let :countries do
        <<-EOF
          United Kingdom # This is a test

             Ireland

        EOF
      end

      it "they are stripped" do
        expect(subject.allowed_countries).to eq([country_1, country_2])
      end
    end
  end
end
