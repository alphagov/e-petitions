require 'rails_helper'

describe StaticPagesController do
  describe "home" do
    it "should respond to root path" do
      expect({:get => "/"}).to route_to({:controller => "static_pages", :action => "home"})
      expect(home_path).to eq "/"
    end

    it "assigns trending petitions" do
      trending_petitions = [double]
      allow(Petition).to receive_messages(:last_hour_trending => trending_petitions)
      get :home
      expect(assigns(:trending_petitions)).to eq trending_petitions
    end
  end

  describe "help" do
    it "should respond to /help" do
      expect({:get => "/help"}).to route_to({:controller => "static_pages", :action => "help"})
      expect(help_path).to eq "/help"
    end
  end
end
