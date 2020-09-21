require 'rails_helper'

RSpec.describe "pages", type: :routes do
  describe "routes" do
    it "GET / routes to pages#index" do
      expect({:get => "/"}).to route_to({:controller => "pages", :action => "index"})
    end

    it "GET /help routes to pages#help" do
      expect({:get => "/help"}).to route_to({:controller => "pages", :action => "help"})
    end

    it "should respond to /privacy" do
      expect({:get => "/privacy"}).to route_to({:controller => "pages", :action => "privacy"})
    end

    it "should respond to /accessibility" do
      expect({:get => "/accessibility"}).to route_to({:controller => "pages", :action => "accessibility"})
    end
  end

  describe "helpers" do
    it "#home_url generates https://petition.parliament.uk/" do
      expect(home_url).to eq("https://petition.parliament.uk/")
    end

    it "#help_url generates https://petition.parliament.uk/help" do
      expect(help_url).to eq("https://petition.parliament.uk/help")
    end

    it "#privacy_url generates https://petition.parliament.uk/privacy" do
      expect(privacy_url).to eq("https://petition.parliament.uk/privacy")
    end

    it "#accessibility_url generates https://petition.parliament.uk/accessibility" do
      expect(accessibility_url).to eq("https://petition.parliament.uk/accessibility")
    end
  end
end
