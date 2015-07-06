require 'rails_helper'

RSpec.describe Admin::PetitionsController, type: :controller, admin: true do
  include ActiveJob::TestHelper

  let(:creator_signature) { FactoryGirl.create(:signature, :email => 'john@example.com') }
  let(:petition) { FactoryGirl.create(:sponsored_petition, :creator_signature => creator_signature) }

  describe "not logged in" do
    describe "GET 'index'" do
      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end

    describe "GET 'show'" do
      it "redirects to the login page" do
        get :show, :id => petition.id
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
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
      expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/profile/#{@user.id}/edit")
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

      describe "when no 'q', 't', or 'state' param is present" do
        it "fetchs a list of 50 petitions" do
          expect(Petition).to receive(:search).with(hash_including(count: 50)).and_return Petition.none
          get :index
        end
        it "passes on pagination params" do
          expect(Petition).to receive(:search).with(hash_including(page: '3')).and_return Petition.none
          get :index, page: '3'
        end
      end

      describe "when a 'q' param is present" do
        it "passes in the q param to perform a search for" do
          expect(Petition).to receive(:search).with(hash_including(q: 'lorem')).and_return Petition.none
          get :index, q: 'lorem'
        end
        it "passes on pagination params" do
          expect(Petition).to receive(:search).with(hash_including(page: '3')).and_return Petition.none
          get :index, q: 'lorem', page: '3'
        end
      end

      describe "when a 't' param is present" do
        let(:petition_scope) { Petition.none }
        it "avoids search entirely" do
          expect(Petition).not_to receive(:search)
          get :index, t: 'a tag'
        end
        it "uses the t param to find tagged petitions" do
          expect(Petition).to receive(:tagged_with).with('a tag').and_return petition_scope
          get :index, t: 'a tag'
        end
        it "passes on pagination params" do
          allow(Petition).to receive(:tagged_with).and_return petition_scope
          expect(petition_scope).to receive(:paginate).with(page: '3', per_page: 50).and_return petition_scope
          get :index, t: 'a tag', page: '3'
        end
        context 'and `q` is also present' do
          it 'does a search, not a tagged filter' do
            expect(Petition).to receive(:search)
            expect(Petition).not_to receive(:tagged_with)
            get :index, t: 'a tag', q: 'lorem'
          end
        end
        context 'and `state` is also present' do
          it 'does a search, not a tagged filter' do
            expect(Petition).to receive(:search)
            expect(Petition).not_to receive(:tagged_with)
            get :index, t: 'a tag', state: 'open'
          end
        end
      end

      describe 'when a `state` param is present' do
        it "passes in the state param to perform a search for" do
          expect(Petition).to receive(:search).with(hash_including(state: 'open')).and_return Petition.none
          get :index, state: 'open'
        end
        it "passes on pagination params" do
          expect(Petition).to receive(:search).with(hash_including(page: '3')).and_return Petition.none
          get :index, state: 'open', page: '3'
        end
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
