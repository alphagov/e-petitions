require 'rails_helper'

RSpec.describe HomeHelper, type: :helper do
  describe "#action_count" do
    describe "for counting the moderation queue" do
      it "returns a HTML-safe string" do
        expect(helper.action_count(:in_moderation, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the action count is 1" do
        it "returns a correctly formatted action count" do
          expect(helper.action_count(:in_moderation, 1)).to eq("<span class=\"count\">1</span> Moderation queue")
        end
      end

      context "when the action count is 1000" do
        it "returns a correctly formatted action count" do
          expect(helper.action_count(:in_moderation, 1000)).to eq("<span class=\"count\">1,000</span> Moderation queue")
        end
      end
    end

    describe "for counting the government response queue" do
      it "returns a HTML-safe string" do
        expect(helper.action_count(:awaiting_response, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the action count is 1" do
        it "returns a correctly formatted action count" do
          expect(helper.action_count(:awaiting_response, 1)).to eq("<span class=\"count\">1</span> Government response queue")
        end
      end

      context "when the action count is 1000" do
        it "returns a correctly formatted action count" do
          expect(helper.action_count(:awaiting_response, 1000)).to eq("<span class=\"count\">1,000</span> Government response queue")
        end
      end
    end

    describe "for counting the debate queue" do
      it "returns a HTML-safe string" do
        expect(helper.action_count(:in_debate_queue, 1)).to be_an(ActiveSupport::SafeBuffer)
      end

      context "when the action count is 1" do
        it "returns a correctly formatted action count" do
          expect(helper.action_count(:in_debate_queue, 1)).to eq("<span class=\"count\">1</span> Debate queue")
        end
      end

      context "when the action count is 1000" do
        it "returns a correctly formatted action count" do
          expect(helper.action_count(:in_debate_queue, 1000)).to eq("<span class=\"count\">1,000</span> Debate queue")
        end
      end
    end
  end
end
