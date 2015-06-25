require 'rails_helper'

RSpec.describe SignatureHelper, type: :helper do
  describe "#signature_count" do
    describe "for normal petition lists" do
      it "returns a HTML-safe string" do
        expect(helper.signature_count(:default, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the signature count is 1" do
        it "returns a correctly formatted signature count" do
          expect(helper.signature_count(:default, 1)).to eq("1 <span>signature</span>")
        end
      end

      context "when the signature count is 100" do
        it "returns a correctly formatted signature count" do
          expect(helper.signature_count(:default, 100)).to eq("100 <span>signatures</span>")
        end
      end

      context "when the signature count is 1000" do
        it "returns a correctly formatted signature count" do
          expect(helper.signature_count(:default, 1000)).to eq("1,000 <span>signatures</span>")
        end
      end
    end

    describe "for trending petition lists" do
      it "returns a HTML-safe string" do
        expect(helper.signature_count(:trending, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the signature count is 1" do
        it "returns a correctly formatted signature count" do
          expect(helper.signature_count(:trending, 1)).to eq("<span class=\"count\">1</span> signature in the last hour")
        end
      end

      context "when the signature count is 100" do
        it "returns a correctly formatted signature count" do
          expect(helper.signature_count(:trending, 100)).to eq("<span class=\"count\">100</span> signatures in the last hour")
        end
      end

      context "when the signature count is 1000" do
        it "returns a correctly formatted signature count" do
          expect(helper.signature_count(:trending, 1000)).to eq("<span class=\"count\">1,000</span> signatures in the last hour")
        end
      end
    end

    describe "for petitions in your constituency" do
      it "returns a HTML-safe string" do
        expect(helper.signature_count(:in_your_constituency, 1, constituency: 'North Votingshire')).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the signature count is 1" do
        it "returns a correctly formatted signature count" do
          expect(helper.signature_count(:in_your_constituency, 1, constituency: 'North Votingshire')).to eq("1 signature from North Votingshire")
        end
      end

      context "when the signature count is 100" do
        it "returns a correctly formatted signature count" do
          expect(helper.signature_count(:in_your_constituency, 100, constituency: 'North Votingshire')).to eq("100 signatures from North Votingshire")
        end
      end

      context "when the signature count is 1000" do
        it "returns a correctly formatted signature count" do
          expect(helper.signature_count(:in_your_constituency, 1000, constituency: 'North Votingshire')).to eq("1,000 signatures from North Votingshire")
        end
      end
    end
  end
end
