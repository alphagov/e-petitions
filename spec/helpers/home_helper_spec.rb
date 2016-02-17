require 'rails_helper'

RSpec.describe HomeHelper, type: :helper do
  describe "#no_petitions_yet?" do
    let(:connection) { Petition.connection }
    let(:sql) { /^SELECT COUNT/ }

    it "performs a count query" do
      expect(connection).to receive(:select).with(sql, any_args).and_call_original
      expect(helper.no_petitions_yet?).to be true
    end

    it "it caches the result" do
      expect(connection).to receive(:select).once.with(sql, any_args).and_call_original
      expect(helper.no_petitions_yet?).to be true
      expect(helper.no_petitions_yet?).to be true
    end

    context "when there are no published petitions" do
      before do
        FactoryGirl.create(:pending_petition)
      end

      it "returns true" do
        expect(helper.no_petitions_yet?).to be true
      end
    end

    Petition::VISIBLE_STATES.each do |state|
      context "when there is a #{state} petition" do
        before do
          FactoryGirl.create(:"#{state}_petition")
        end

        it "returns false" do
          expect(helper.no_petitions_yet?).to be false
        end
      end
    end
  end

  describe "#petition_count" do
    describe "for counting government responses" do
      it "returns a HTML-safe string" do
        expect(helper.petition_count(:with_response, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the petition count is 1" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_response, 1)).to eq("<span class=\"count\">1</span> petition got a response from the Government")
        end
      end

      context "when the petition count is 100" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_response, 100)).to eq("<span class=\"count\">100</span> petitions got a response from the Government")
        end
      end

      context "when the petition count is 1000" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_response, 1000)).to eq("<span class=\"count\">1,000</span> petitions got a response from the Government")
        end
      end
    end

    describe "for counting debated petitions" do
      it "returns a HTML-safe string" do
        expect(helper.petition_count(:with_debated_outcome, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the petition count is 1" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_debated_outcome, 1)).to eq("<span class=\"count\">1</span> petition was debated in the House of Commons")
        end
      end

      context "when the petition count is 100" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_debated_outcome, 100)).to eq("<span class=\"count\">100</span> petitions were debated in the House of Commons")
        end
      end

      context "when the petition count is 1000" do
        it "returns a correctly formatted petition count" do
          expect(helper.petition_count(:with_debated_outcome, 1000)).to eq("<span class=\"count\">1,000</span> petitions were debated in the House of Commons")
        end
      end
    end
  end
end
