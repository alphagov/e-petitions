require 'rails_helper'

RSpec.describe AdminHubHelper, type: :helper do
  describe "moderation count helpers" do
    before do
      allow(Admin::Settings).to receive(:first).and_return(Admin::Settings.create(petition_tags: "one"))
    end

    let!(:petition_recently_in_moderation) { FactoryGirl.create(:recently_in_moderation_petition) }
    let!(:petition_nearly_overdue_moderation) { FactoryGirl.create(:nearly_overdue_moderation_petition) }
    let!(:petition_overdue_moderation) { FactoryGirl.create(:overdue_moderation_petition) }
    let!(:tagged_in_moderation_petition) { FactoryGirl.create(:validated_petition, tags: ['one']) }
    let!(:sponsored_petition) { FactoryGirl.create(:sponsored_petition, tags: ['one']) }

    describe "in_moderation_count" do
      it 'returns the number in moderation' do
        expect(helper.in_moderation_count).to eq 4
      end
    end

    describe "recently_in_moderation_count" do
      it 'returns the number recently in moderation' do
        expect(helper.recently_in_moderation_count).to eq 1
      end
    end

    describe "nearly_overdue_moderation_count" do
      it 'returns the number nearly overdue moderation' do
        expect(helper.nearly_overdue_moderation_count).to eq 1
      end
    end

    describe "overdue_moderation_count" do
      it 'returns the number overdue moderation' do
        expect(helper.overdue_moderation_count).to eq 1
      end
    end

    describe "tagged_count" do
      it 'returns the number of tagged petitions' do
        expect(helper.tagged_count).to eq 1
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
