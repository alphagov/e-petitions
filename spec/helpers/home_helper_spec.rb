require 'rails_helper'

RSpec.describe HomeHelper, type: :helper do
  describe "#petition_count" do
    describe "for counting government responses" do
      it "returns a HTML-safe string" do
        expect(helper.petition_count(:with_response, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the petition count is 1" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_response, 1)).to eq("<span class=\"count\">1</span> petition got a response from government")
        end
      end

      context "when the petition count is 100" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_response, 100)).to eq("<span class=\"count\">100</span> petitions got a response from government")
        end
      end

      context "when the petition count is 1000" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_response, 1000)).to eq("<span class=\"count\">1,000</span> petitions got a response from government")
        end
      end
    end

    describe "for counting debated petitions" do
      it "returns a HTML-safe string" do
        expect(helper.petition_count(:with_debate_outcome, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the petition count is 1" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_debate_outcome, 1)).to eq("<span class=\"count\">1</span> petition was debated in parliament")
        end
      end

      context "when the petition count is 100" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_debate_outcome, 100)).to eq("<span class=\"count\">100</span> petitions were debated in parliament")
        end
      end

      context "when the petition count is 1000" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_debate_outcome, 1000)).to eq("<span class=\"count\">1,000</span> petitions were debated in parliament")
        end
      end
    end
  end
end
