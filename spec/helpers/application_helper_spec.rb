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

  describe "#create_petition_page?" do
    context "when on the check petition page" do
      before do
        params[:controller] = "petitions"
        params[:action] = "check"
      end

      it "returns true" do
        expect(helper.create_petition_page?).to eq(true)
      end
    end

    context "when on the new petition page" do
      before do
        params[:controller] = "petitions"
        params[:action] = "new"
      end

      it "returns true" do
        expect(helper.create_petition_page?).to eq(true)
      end
    end

    context "when on the create petition page" do
      before do
        params[:controller] = "petitions"
        params[:action] = "create"
      end

      it "returns true" do
        expect(helper.create_petition_page?).to eq(true)
      end
    end

    context "when not on a create petition page" do
      before do
        params[:controller] = "pages"
        params[:action] = "index"
      end

      it "returns false" do
        expect(helper.create_petition_page?).to eq(false)
      end
    end
  end
end
