require 'rails_helper'

RSpec.describe "pages", type: :routes do
  describe "routes" do
    it "GET / routes to pages#index" do
      expect(get: "/").to route_to(controller: "pages", action: "index")
    end

    it "GET /accessibility routes to pages#show" do
      expect(get: "/accessibility").to route_to(controller: "pages", action: "show", slug: "accessibility")
    end

    it "GET /cookies routes to pages#show" do
      expect(get: "/cookies").to route_to(controller: "pages", action: "show", slug: "cookies")
    end

    it "GET /help routes to pages#show" do
      expect(get: "/help").to route_to(controller: "pages", action: "show", slug: "help")
    end

    it "GET /privacy routes to pages#show" do
      expect(get: "/privacy").to route_to(controller: "pages", action: "show", slug: "privacy")
    end
  end

  describe "helpers" do
    it "#home_url generates https://petition.parliament.uk/" do
      expect(home_url).to eq("https://petition.parliament.uk/")
    end

    it "#accessibility_url generates https://petition.parliament.uk/accessibility" do
      expect(accessibility_url).to eq("https://petition.parliament.uk/accessibility")
    end

    it "#cookies_url generates https://petition.parliament.uk/cookies" do
      expect(accessibility_url).to eq("https://petition.parliament.uk/accessibility")
    end

    it "#help_url generates https://petition.parliament.uk/help" do
      expect(help_url).to eq("https://petition.parliament.uk/help")
    end

    it "#privacy_url generates https://petition.parliament.uk/privacy" do
      expect(privacy_url).to eq("https://petition.parliament.uk/privacy")
    end

    it "#browserconfig_url" do
      expect(browserconfig_url).to eq("https://petition.parliament.uk/browserconfig.xml")
    end

    it "#manifest_url" do
      expect(manifest_url).to eq("https://petition.parliament.uk/manifest.json")
    end

    it "#trending_url" do
      expect(trending_url).to eq("https://petition.parliament.uk/trending.json")
    end
  end
end
