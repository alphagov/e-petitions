require 'rails_helper'

RSpec.describe Admin::CompletionDateController, type: :controller, admin: true do
  let(:petition) do
    FactoryBot.create(:completed_petition, completed_at: "2020-04-24T12:00:00Z")
  end

  describe "not logged in" do
    describe "GET /admin/petitions/:petition_id/completion-date" do
      it "redirects to the login page" do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end

    describe "PATCH /admin/petitions/:petition_id/completion-date" do
      it "redirects to the login page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "GET /admin/petitions/:petition_id/completion-date" do
      it "redirects to the login page" do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end

    describe "PATCH /admin/petitions/:petition_id/completion-date" do
      it "redirects to edit profile page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /admin/petitions/:petition_id/completion-date" do
      it "fetches the requested petition" do
        get :show, params: { petition_id: petition.id }
        expect(assigns(:petition)).to eq petition
      end

      it "responds successfully and renders the petitions/show template" do
        get :show, params: { petition_id: petition.id }
        expect(response).to be_successful
        expect(response).to render_template('petitions/show')
      end
    end

    describe "PATCH /admin/petitions/:petition_id/completion-date" do
      let(:params) do
        {
          "completed_at(3i)"=>"29",
          "completed_at(2i)"=>"02",
          "completed_at(1i)"=>"2020",
          "completed_at(4i)"=>"0",
          "completed_at(5i)"=>"0",
          "completed_at(6f)"=>"0"
        }
      end

      it "updates the completion date" do
        expect {
          patch :update, params: { petition_id: petition.id, petition: params }
        }.to change {
          petition.reload.completed_at
        }.from(
          "2020-04-24T12:00:00Z".in_time_zone
        ).to(
          "2020-02-29T00:00:00Z".in_time_zone
        )
      end

      it "redirects to the petition page" do
        patch :update, params: { petition_id: petition.id, petition: params }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}")
      end

      it "displays a notice" do
        patch :update, params: { petition_id: petition.id, petition: params }
        expect(flash[:notice]).to eq("The completion date was successfully updated")
      end
    end
  end
end
