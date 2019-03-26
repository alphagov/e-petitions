require 'rails_helper'

RSpec.describe ModerationHelper, type: :helper do
  describe "#moderation_delay?" do
    let(:scope) { double(Petition) }

    before do
      allow(Petition).to receive(:in_moderation).and_return(scope)
      allow(scope).to receive(:count).and_return(moderation_queue)
    end

    context "when there are less than 500 petitions in the moderation queue" do
      let(:moderation_queue) { 499 }

      it "returns false" do
        expect(helper.moderation_delay?).to eq(false)
      end
    end

    context "when there are 500 petitions in the moderation queue" do
      let(:moderation_queue) { 500 }

      it "returns true" do
        expect(helper.moderation_delay?).to eq(true)
      end
    end

    context "when there are more than 500 petitions in the moderation queue" do
      let(:moderation_queue) { 501 }

      it "returns true" do
        expect(helper.moderation_delay?).to eq(true)
      end
    end
  end
end
