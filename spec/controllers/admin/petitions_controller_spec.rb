require 'rails_helper'

RSpec.describe Admin::PetitionsController, type: :controller do
  include ActiveJob::TestHelper

  before :each do
    creator_signature = FactoryGirl.create(:signature, :email => 'john@example.com')
    @petition = FactoryGirl.create(:sponsored_petition, :creator_signature => creator_signature)
  end

  describe "not logged in" do
    describe "GET 'index'" do
      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end

    describe "GET 'show'" do
      it "redirects to the login page" do
        get :show, :id => @petition.id
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    before :each do
      @user = FactoryGirl.create(:moderator_user, :force_password_reset => true)
      login_as(@user)
    end

    it "redirects to edit profile page" do
      expect(@user.has_to_change_password?).to be_truthy
      get :show, :id => @petition.id
      expect(response).to redirect_to("https://petition.parliament.uk/admin/profile/#{@user.id}/edit")
    end
  end

  describe "logged in as moderator user" do
    before :each do
      @user = FactoryGirl.create(:moderator_user)
      login_as(@user)

      @p1 = FactoryGirl.create(:open_petition)
      @p1.update_attribute(:signature_count, 11)
      @p2 = FactoryGirl.create(:open_petition)
      @p2.update_attribute(:signature_count, 10)
      @p3 = FactoryGirl.create(:open_petition)
      @p3.update_attribute(:signature_count, 9)
      @p4 = FactoryGirl.create(:closed_petition)
      @p4.update_attribute(:signature_count, 20)

      allow(Site).to receive(:threshold_for_debate).and_return(10)
    end
  end

  describe "logged in as sysadmin" do
    before :each do
      @user = FactoryGirl.create(:sysadmin_user)
      login_as(@user)
    end

    context "show" do
      it "assigns petition successfully" do
        get :show, :id => @petition.id
        expect(assigns(:petition)).to eq(@petition)
      end
    end
  end
end
