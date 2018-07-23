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
  end
end
