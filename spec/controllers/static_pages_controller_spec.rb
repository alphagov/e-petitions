require 'rails_helper'

RSpec.describe StaticPagesController, type: :controller do
  describe "home" do
    it "should respond to root path" do
      expect({:get => "/"}).to route_to({:controller => "static_pages", :action => "home"})
      expect(home_path).to eq "/"
    end
  end

  describe "help" do
    it "should respond to /help" do
      expect({:get => "/help"}).to route_to({:controller => "static_pages", :action => "help"})
      expect(help_path).to eq "/help"
    end
  end
end
