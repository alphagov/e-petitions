require 'spec_helper'

describe Admin::TodolistController do

  describe "not logged in" do
    with_ssl do
      describe "GET 'index'" do
        it "should redirect to the login page" do
          get 'index'
          response.should redirect_to(admin_login_path)
        end
      end
    end
  end
  
  context "logged in as admin user but need to reset password" do
    before :each do
      @user = Factory.create(:admin_user, :force_password_reset => true)
      login_as(@user)
    end
    
    with_ssl do
      it "should redirect to edit profile page" do
        @user.has_to_change_password?.should be_true
        get :index
        response.should redirect_to(edit_admin_profile_path(@user))
      end
    end
  end
  
  describe "logged in" do
    before :each do
      @treasury = Factory(:department)
      @dfid = Factory(:department)
      @home_office = Factory(:department)
      @p1 = Factory(:petition, :department => @treasury, :created_at => 3.days.ago, :state => Petition::VALIDATED_STATE)
      @p2 = Factory(:petition, :department => @treasury, :created_at => 12.days.ago, :state => Petition::VALIDATED_STATE)
      @p3 = Factory(:petition, :department => @home_office, :created_at => 7.days.ago, :state => Petition::VALIDATED_STATE)
      @p4 = Factory(:petition, :department => @home_office, :state => Petition::PENDING_STATE)
      @p5 = Factory(:open_petition, :department => @dfid)
    end
    
    describe "logged in as sysadmin user" do
      before :each do
        @user = Factory.create(:sysadmin_user)
        login_as(@user)
      end
      
      without_ssl do
        describe "GET 'index'" do
          it "should redirect to ssl" do
            get :index
            response.should redirect_to(admin_root_url(:protocol => 'https'))
          end
        end
      end
      
      with_ssl do
        describe "GET 'index'" do
          it "should be successful" do
            get :index
            response.should be_success
          end
        
          it "should return all validated petitions ordered by created_at" do
            get :index
            assigns[:petitions].should == [@p2, @p3, @p1]
          end
        end
      end
    end
    
    describe "logged in as threshold user" do
      before :each do
        @user = Factory.create(:threshold_user)
        login_as(@user)
      end
      
      with_ssl do
        describe "GET 'index'" do
          it "should be successful" do
            get :index
            response.should be_success
          end
        
          it "should return all validated petitions ordered by created_at" do
            get :index
            assigns[:petitions].should == [@p2, @p3, @p1]
          end
        end
      end
    end

    describe "logged in as admin user" do
      before :each do
        @user = Factory.create(:admin_user)
        @user.departments << @treasury << @dfid
        login_as(@user)
      end
      
      with_ssl do
        describe "GET 'index'" do
          it "should be successful" do
            get :index
            response.should be_success
          end
        
          it "should return validated petitions for the user's department(s)" do
            get :index
            assigns[:petitions].should == [@p2, @p1]
          end
        end
      end
    end
  end
end
