require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe "home" do
    it "should respond to root path" do
      expect({:get => "/"}).to route_to({:controller => "pages", :action => "index"})
      expect(home_path).to eq "/"
    end
  end

  describe "help" do
    it "should respond to /help" do
      expect({:get => "/help"}).to route_to({:controller => "pages", :action => "help"})
      expect(help_path).to eq "/help"
    end
  end

  describe "privacy" do
    it "should respond to /privacy" do
      expect({:get => "/privacy"}).to route_to({:controller => "pages", :action => "privacy"})
      expect(privacy_path).to eq "/privacy"
    end
  end
end
