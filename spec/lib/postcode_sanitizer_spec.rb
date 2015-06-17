require 'spec_helper'
require 'postcode_sanitizer'

RSpec.describe PostcodeSanitizer do
  describe '.call' do
    it "removes all whitespace" do
      postcode = " N1  1TY  "
      expect(described_class.call(postcode)).to eq "N11TY"
    end
    it "upcases the postcode" do
      postcode = "n11ty "
      expect(described_class.call(postcode)).to eq "N11TY"
    end
    it "removes whitespaces and upcase the postcode" do
      postcode = "   N1  1ty "
      expect(described_class.call(postcode)).to eq "N11TY"
    end
  end
end
