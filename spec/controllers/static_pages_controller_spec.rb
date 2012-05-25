require 'spec_helper'

describe StaticPagesController do
  describe "home" do
    it "should respond to root path" do
      {:get => "/"}.should route_to({:controller => "static_pages", :action => "home"})
      home_path.should == "/"
    end

    it "assigns trending petitions" do
      trending_petitions = [double]
      TrendingPetition.stub(:order => double(:limit => trending_petitions))
      get :home
      assigns(:trending_petitions).should   == trending_petitions[0..5]
      assigns(:additional_petitions).should == trending_petitions[6..11]
    end
  end

  describe "terms_and_conditions" do
    it "should respond to /terms-and-conditions" do
      {:get => "/terms-and-conditions"}.should route_to({:controller => "static_pages", :action => "terms_and_conditions"})
      terms_and_conditions_path.should == "/terms-and-conditions"
    end
  end
  describe "privacy_policy" do
    it "should respond to /privacy-policy" do
      {:get => "/privacy-policy"}.should route_to({:controller => "static_pages", :action => "privacy_policy"})
      privacy_policy_path.should == "/privacy-policy"
    end
  end
  describe "crown_copyright" do
    it "should respond to /crown-copyright" do
      {:get => "/crown-copyright"}.should route_to({:controller => "static_pages", :action => "crown_copyright"})
      crown_copyright_path.should == "/crown-copyright"
    end
  end
end
