require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#home_page?" do
    context "when on the home page" do
      before do
        params[:controller] = "pages"
        params[:action] = "index"
      end

      it "returns true" do
        expect(helper.home_page?).to eq(true)
      end
    end

    context "when not on the home page" do
      before do
        params[:controller] = "pages"
        params[:action] = "help"
      end

      it "returns false" do
        expect(helper.home_page?).to eq(false)
      end
    end
  end
end
