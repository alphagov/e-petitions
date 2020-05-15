require 'rails_helper'

RSpec.describe Admin::AbmsLinkController, type: :controller, admin: true do

  let!(:petition) { FactoryBot.create(:closed_petition) }

  describe "not logged in" do
    describe "GET /show" do
      it "redirects to the login page" do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end

    describe "PATCH /update" do
      it "redirects to the login page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "GET /show" do
      it "redirects to edit profile page" do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end

    describe "PATCH /update" do
      it "redirects to edit profile page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /show" do
      it "fetches the requested petition" do
        get :show, params: { petition_id: petition.id }
        expect(assigns(:petition)).to eq petition
      end

      it "responds successfully and renders the petitions/show template" do
        get :show, params: { petition_id: petition.id }
        expect(response).to be_successful
        expect(response).to render_template("petitions/show")
      end
    end

    describe "PATCH /update" do
      let(:attributes) do
        {
          abms_link_en: "https://business.senedd.wales/mgIssueHistoryHome.aspx?IId=27662&Opt=0",
          abms_link_cy: "https://busnes.senedd.cymru/mgIssueHistoryHome.aspx?IId=27662&Opt=0"
        }
      end

      before do
        patch :update, params: { petition_id: petition.id, petition: attributes }
      end

      it "fetches the requested petition" do
        expect(assigns(:petition)).to eq petition
      end

      it "redirects to the petition show page" do
        expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}"
      end

      it "sets the flash notice message" do
        expect(flash[:notice]).to eq("Petition has been successfully updated")
      end

      it "stores the English link in the database" do
        expect {
          petition.reload
        }.to change {
          petition.abms_link_en
        }.from(nil).to(a_string_matching("business.senedd.wales"))
      end

      it "stores the Welsh link in the database" do
        expect {
          petition.reload
        }.to change {
          petition.abms_link_cy
        }.from(nil).to(a_string_matching("busnes.senedd.cymru"))
      end
    end
  end
end
