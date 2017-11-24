require 'rails_helper'

RSpec.describe AdminHubHelper, type: :helper do
  describe "moderation count helpers" do
    let!(:tag) { FactoryBot.create(:tag, name: "one") }
    let!(:petition_recently_in_moderation) { FactoryBot.create(:sponsored_petition, :recent) }
    let!(:petition_nearly_overdue_moderation) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }
    let!(:petition_overdue_moderation) { FactoryBot.create(:sponsored_petition, :overdue) }
    let!(:tagged_in_moderation_petition) { FactoryBot.create(:sponsored_petition, tags: [tag.id]) }

    describe "in_moderation_count" do
      it "returns the number in moderation" do
        expect(helper.in_moderation_count).to eq 4
      end
    end

    describe "recently_in_moderation_count" do
      it "returns the number recently in moderation" do
        expect(helper.recently_in_moderation_count).to eq 2
      end
    end

    describe "recently_in_moderation_untagged_count" do
      it "returns the number recently in moderation that are untagged" do
        expect(helper.recently_in_moderation_untagged_count).to eq 1
      end
    end

    describe "nearly_overdue_in_moderation_count" do
      it "returns the number nearly overdue moderation" do
        expect(helper.nearly_overdue_in_moderation_count).to eq 1
      end
    end

    describe "nearly_overdue_in_moderation_untagged_count" do
      it "returns the number nearly overdue moderation that are untagged" do
        expect(helper.nearly_overdue_in_moderation_untagged_count).to eq 1
      end
    end

    describe "overdue_in_moderation_count" do
      it "returns the number overdue moderation" do
        expect(helper.overdue_in_moderation_count).to eq 1
      end
    end

    describe "overdue_in_moderation_untagged_count" do
      it "returns the number overdue moderation that are untagged" do
        expect(helper.overdue_in_moderation_untagged_count).to eq 1
      end
    end

    describe "tagged_in_moderation_count" do
      it "returns the number of tagged petitions" do
        expect(helper.tagged_in_moderation_count).to eq 1
      end
    end

    describe "untagged_in_moderation_count" do
      it "returns the number of untagged petitions" do
        expect(helper.untagged_in_moderation_count).to eq 3
      end
    end
  end

  describe "#summary_class_name_for_in_moderation" do
    before { FactoryBot.create(:sponsored_petition, :recent) }

    context "when there are no overdue and nearly overdue petitions" do
      it "returns the CSS class name 'queue-stable'" do
        expect(helper.summary_class_name_for_in_moderation).to eq("queue-stable")
      end
    end

    context "when there are no overdue but there are nearly overdue petitions" do
      before { FactoryBot.create(:sponsored_petition, :nearly_overdue) }

      it "returns the CSS class name 'queue-caution'" do
        expect(helper.summary_class_name_for_in_moderation).to eq("queue-caution")
      end
    end

    context "when there are overdue petitions" do
      before { FactoryBot.create(:sponsored_petition, :overdue) }

      it "returns the CSS class name 'queue-danger'" do
        expect(helper.summary_class_name_for_in_moderation).to eq("queue-danger")
      end
    end
  end

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
