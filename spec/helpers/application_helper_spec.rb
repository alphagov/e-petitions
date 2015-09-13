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

  describe "#petition_page?" do
    context "when on the show petition page" do
      before do
        params[:controller] = "petitions"
        params[:action] = "show"
      end

      it "returns true" do
        expect(helper.petition_page?).to eq(true)
      end
    end

    context "when not on the show petition page" do
      before do
        params[:controller] = "pages"
        params[:action] = "index"
      end

      it "returns false" do
        expect(helper.petition_page?).to eq(false)
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

  describe "#back_url" do
    let(:headers) { helper.request.env }

    before do
      headers["HTTP_HOST"]   = "petition.parliament.test"
      headers["HTTPS"]       = "on"
      headers["SERVER_PORT"] = 443
    end

    context "when the referer is an internal url" do
      before do
        headers["HTTP_REFERER"] = "https://petition.parliament.test/petitions/new"
      end

      it "returns the referer url" do
        expect(helper.back_url).to eq("https://petition.parliament.test/petitions/new")
      end
    end

    context "when the referer is invalid" do
      before do
        headers["HTTP_REFERER"] = "javascript:alert('Hello, World!')"
      end

      it "returns 'javascript:history.back()'" do
        expect(helper.back_url).to eq("javascript:history.back()")
      end
    end

    context "when the scheme doesn't match" do
      before do
        headers["HTTP_REFERER"] = "http://petition.parliament.test/petitions/new"
      end

      it "returns 'javascript:history.back()'" do
        expect(helper.back_url).to eq("javascript:history.back()")
      end
    end

    context "when the host doesn't match" do
      before do
        headers["HTTP_REFERER"] = "https://petition.gov.uk"
      end

      it "returns 'javascript:history.back()'" do
        expect(helper.back_url).to eq("javascript:history.back()")
      end
    end

    context "when the port doesn't match" do
      before do
        headers["HTTP_REFERER"] = "http://petition.parliament.test:8443/petitions/new"
      end

      it "returns 'javascript:history.back()'" do
        expect(helper.back_url).to eq("javascript:history.back()")
      end
    end
  end

  describe "#noindex_page?" do
    context "when on a page that should not be indexed by search engines" do
      before do
        params[:controller] = "signatures"
        params[:action] = "new"
      end

      it "returns true" do
        expect(helper.noindex_page?).to eq(true)
      end
    end

    context "when on a page that should be indexed by search engines" do
      before do
        params[:controller] = "petitions"
        params[:action] = "show"
      end

      it "returns false" do
        expect(helper.noindex_page?).to eq(false)
      end
    end
  end
end
