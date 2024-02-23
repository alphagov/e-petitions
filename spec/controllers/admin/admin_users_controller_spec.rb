require 'rails_helper'

RSpec.describe Admin::AdminUsersController, type: :controller, admin: true do
  context "not logged in" do
    describe "GET 'index'" do
      it "should redirect to the login page" do
        get 'index'
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end
  end

  context "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before :each do
      login_as(user)
    end

    describe "GET 'index'" do
      it "should be unsuccessful" do
        get :index
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin")
      end
    end
  end

  describe "logged in as sysadmin user" do
    let(:user) { FactoryBot.create(:sysadmin_user, :first_name => 'Sys', :last_name => 'Admin') }
    before :each do
      login_as(user)
    end

    describe "GET 'index'" do
      before :each do
        @user1 = FactoryBot.create(:moderator_user, :first_name => 'John', :last_name => 'Kennedy')
        @user2 = FactoryBot.create(:moderator_user, :first_name => 'Hilary', :last_name => 'Clinton')
        @user3 = FactoryBot.create(:moderator_user, :first_name => 'Ronald', :last_name => 'Reagan')
        @user4 = FactoryBot.create(:moderator_user, :first_name => 'Bill', :last_name => 'Clinton')
      end

      it "should be successful" do
        get :index
        expect(response).to be_successful
      end

      it "should display a list of users (sorted by name)" do
        get :index
        expect(assigns[:users]).to eq([user, @user4, @user2, @user1, @user3])
      end
    end
  end
end
