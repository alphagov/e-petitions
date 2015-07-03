require 'rails_helper'

RSpec.describe Admin::PetitionsController, type: :controller do
  include ActiveJob::TestHelper

  let(:creator_signature) { FactoryGirl.create(:signature, :email => 'john@example.com') }
  let(:petition) { FactoryGirl.create(:sponsored_petition, :creator_signature => creator_signature) }

  describe "not logged in" do
    describe "GET 'index'" do
      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end

    describe "GET 'show'" do
      it "redirects to the login page" do
        get :show, :id => petition.id
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
      get :show, :id => petition.id
      expect(response).to redirect_to("https://petition.parliament.uk/admin/profile/#{@user.id}/edit")
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryGirl.create(:moderator_user) }
    before { login_as(user) }

    describe "GET 'index'" do
      it "responds successfully" do
        get :index
        expect(response).to be_success
        expect(response).to render_template('admin/petitions/index')
      end

      it "fetchs a list of 50 petitions" do
        expect(Petition).to receive(:search).with(hash_including(count: 50)).and_return Petition.none
        get :index
      end

      it "passes in the q param to perform a search for" do
        expect(Petition).to receive(:search).with(hash_including(q: 'lorem')).and_return Petition.none
        get :index, q: 'lorem'
      end
    end

    describe "GET 'show'" do
      it "assigns petition successfully" do
        get :show, id: petition.id
        expect(assigns(:petition)).to eq(petition)
      end

      it "responds successfully" do
        get :show, id: petition.id
        expect(response).to be_success
        expect(response).to render_template('admin/petitions/show')
      end
    end
  end
end
