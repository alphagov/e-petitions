require 'rails_helper'

describe StaticPagesController do
  describe "home" do
    it "should respond to root path" do
      expect({:get => "/"}).to route_to({:controller => "static_pages", :action => "home"})
      expect(home_path).to eq "/"
    end

    it "assigns trending petitions" do
      trending_petitions = [double]
      allow(TrendingPetition).to receive_messages(:order => double(:limit => trending_petitions))
      get :home
      expect(assigns(:trending_petitions)).to eq trending_petitions[0..5]
      expect(assigns(:additional_petitions)).to eq trending_petitions[6..11]
    end
  end

  describe "terms_and_conditions" do
    it "should respond to /terms-and-conditions" do
      expect({:get => "/terms-and-conditions"}).to route_to({:controller => "static_pages", :action => "terms_and_conditions"})
      expect(terms_and_conditions_path).to eq "/terms-and-conditions"
    end
  end
  describe "privacy_policy" do
    it "should respond to /privacy-policy" do
      expect({:get => "/privacy-policy"}).to route_to({:controller => "static_pages", :action => "privacy_policy"})
      expect(privacy_policy_path).to eq "/privacy-policy"
    end
  end
end
