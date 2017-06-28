require 'rails_helper'

RSpec.describe Admin::TagsController, type: :controller, admin: true do

  let!(:admin_settings) { Admin::Settings.first_or_create!(petition_tags: "tag 1\ntag 2") }
  let!(:petition) { FactoryGirl.create(:open_petition) }

  describe 'not logged in' do
    describe 'GET /show' do
      it 'redirects to the login page' do
        get :show, petition_id: petition.id
        expect(response).to redirect_to('https://moderate.petition.parliament.uk/admin/login')
      end
    end

    describe 'PATCH /update' do
      it 'redirects to the login page' do
        patch :update, petition_id: petition.id
        expect(response).to redirect_to('https://moderate.petition.parliament.uk/admin/login')
      end
    end
  end

  context 'logged in as moderator user but need to reset password' do
    let(:user) { FactoryGirl.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe 'GET /show' do
      it 'redirects to edit profile page' do
        get :show, petition_id: petition.id
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end

    describe 'PATCH /update' do
      it 'redirects to edit profile page' do
        patch :update, petition_id: petition.id
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryGirl.create(:moderator_user) }
    before { login_as(user) }

    describe 'GET /show' do
      it 'fetches the requested petition' do
        get :show, petition_id: petition.id
        expect(assigns(:petition)).to eq petition
      end

      it 'fetches the site settings' do
        get :show, petition_id: petition.id
        expect(assigns(:admin_settings)).to eq admin_settings
      end

      it 'responds successfully and renders the petitions/show template' do
        get :show, petition_id: petition.id
        expect(response).to be_success
        expect(response).to render_template('petitions/show')
      end
    end

    describe 'PATH /update' do
      it 'fetches the requested petition' do
        patch :update, petition_id: petition.id, petition: { tags: ["tag 1", "tag 2"]}
        expect(assigns(:petition)).to eq petition
      end

      it 'fetches the site settings' do
        patch :update, petition_id: petition.id, petition: { tags: ["tag 1", "tag 2"]}
        expect(assigns(:admin_settings)).to eq admin_settings
      end

      context 'with valid params' do
        it 'updates the tags on the petition' do
          patch :update, petition_id: petition.id, petition: { tags: ["tag 1", "tag 2"]}
          expect(response).to redirect_to admin_petition_path(petition.id)
        end
      end

      context 'with invalid params' do
        it 'renders the admin petitions show template' do
          # tag 3 is not an allowed tag
          patch :update, petition_id: petition.id, petition: { tags: ["tag 3"] }
          expect(response).to render_template 'admin/petitions/show'
        end
      end
    end
  end
end
