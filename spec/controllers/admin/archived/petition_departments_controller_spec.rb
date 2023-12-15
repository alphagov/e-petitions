require 'rails_helper'

RSpec.describe Admin::Archived::PetitionDepartmentsController, type: :controller, admin: true do
  let!(:petition) { FactoryBot.create(:archived_petition) }
  let!(:creator) { FactoryBot.create(:archived_signature, :validated, creator: true, petition: petition) }

  context "when not logged in" do
    describe "GET /admin/archived/petitions/:petition_id/departments" do
      it "redirects to the login page" do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end

    describe "PATCH /admin/archived/petitions/:petition_id/departments" do
      it "redirects to the login page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end
  end

  context "when logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /admin/archived/petitions/:petition_id/departments" do
      before { get :show, params: { petition_id: petition.id } }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :show template" do
        expect(response).to render_template("admin/archived/petitions/show")
      end
    end

    describe "PATCH /admin/archived/petitions/:petition_id/departments" do
      before { patch :update, params: { petition_id: petition.id, petition: params } }

      context "and the params are invalid" do
        let :params do
          { departments: ["999"] }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :show template" do
          expect(response).to render_template("admin/archived/petitions/show")
        end
      end

      context "and the params are empty" do
        let :params do
          { departments: [""] }
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Petition has been successfully updated")
        end
      end

      context "and the params are valid" do
        let(:department) { FactoryBot.create(:department) }

        let :params do
          { departments: [department.id] }
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Petition has been successfully updated")
        end

        it "sets the departments attribute" do
          expect(petition.reload.departments).to eq([department.id])
        end
      end
    end
  end
end
