require 'spec_helper'
require 'postcode_sanitizer'

RSpec.describe PostcodeSanitizer do
  describe ".call" do
    it "removes all whitespace" do
      expect(described_class.call(" N1  1TY  ")).to eq "N11TY"
    end

    it "upcases the postcode" do
      expect(described_class.call("n11ty ")).to eq "N11TY"
    end

    it "removes whitespaces and upcase the postcode" do
      expect(described_class.call("   N1  1ty ")).to eq "N11TY"
    end

    it "removes hypens and upcases the postcode" do
      expect(described_class.call("   N1-1ty ")).to eq "N11TY"
    end

    it "removes en dashes and upcases the postcode" do
      expect(described_class.call("   N1–1ty ")).to eq "N11TY"
    end

    it "removes em dashes and upcases the postcode" do
      expect(described_class.call("   N1—1ty ")).to eq "N11TY"
    end

    it "removes non-alphanumeric characters" do
      expect(described_class.call("acx[[$%7B98*97%7D]]xca")).to eq "ACX7B98977DXCA"
    end
  end
end
