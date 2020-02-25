require 'rails_helper'

RSpec.describe RejectionHelper, type: :helper do
  let(:code) { "duplicate" }

  describe "#rejection_reason" do
    it "gives rejection reason from the locale file" do
      expect(helper.rejection_reason(code)).to eq("Duplicate petition")
    end
  end

  describe "#rejection_description" do
    it "gives rejection description from the locale file" do
      expect(helper.rejection_description(code)).to eq("<p>There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.</p>")
    end

    it "is HTML safe" do
      expect(helper.rejection_description(code)).to be_a(ActiveSupport::SafeBuffer)
    end
  end
end
