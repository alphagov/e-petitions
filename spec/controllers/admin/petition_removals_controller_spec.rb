require 'rails_helper'

RSpec.describe Admin::PetitionRemovalsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/petitions/:petition_id/removal", :show, { petition_id: 1 }],
      ["PATCH", "/admin/petitions/:petition_id/removal", :update, { petition_id: 1 }],
    ].each do |method, path, action, params|

      describe "#{method} #{path}" do
        before { process action, method: method, params: params }

        it "redirects to the login page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
        end
      end

    end
  end

  context "when logged in as a moderator" do
    let(:moderator) { FactoryBot.create(:moderator_user) }
    before { login_as(moderator) }

    [
      ["GET", "/admin/petitions/:petition_id/removal", :show, { petition_id: 1 }],
      ["PATCH", "/admin/petitions/:petition_id/removal", :update, { petition_id: 1 }],
    ].each do |method, path, action, params|

      describe "#{method} #{path}" do
        before { process action, method: method, params: params }

        it "redirects to the admin hub page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin")
        end
      end

    end
  end

  context "when logged in as a sysadmin" do
    let(:sysadmin) { FactoryBot.create(:sysadmin_user) }

    before { login_as(sysadmin) }
    before { allow(Petition).to receive(:find).with(petition.to_param).and_return(petition) }

    describe "GET /admin/petitions/:petition_id/removal" do
      before { get :show, params: { petition_id: petition.id } }

      context "when the petition has been removed" do
        let(:petition) { FactoryBot.create(:removed_petition) }

        it "redirects to the petition show page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Petition has already been removed")
        end
      end

      context "when the petition has not been removed" do
        let(:petition) { FactoryBot.create(:closed_petition) }

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :show template" do
          expect(response).to render_template("admin/petitions/show")
        end
      end
    end

    describe "PATCH /admin/petitions/:petition_id/removal" do
      before { patch :update, params: { petition_id: petition.id, petition: params } }

      context "when the petition has been removed" do
        let(:petition) { FactoryBot.create(:removed_petition) }

        let :params do
          { reason_for_removal: "Removed at the request of the creator" }
        end

        it "redirects to the petition show page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Petition has already been removed")
        end
      end

      context "when the petition has not been removed" do
        let(:petition) { FactoryBot.create(:closed_petition) }

        context "and the params are invalid" do
          let :params do
            { reason_for_removal: "" }
          end

          it "returns 200 OK" do
            expect(response).to have_http_status(:ok)
          end

          it "sets the flash alert message" do
            expect(flash[:alert]).to eq("Petition could not be updated - please check the form for errors")
          end

          it "renders the :show template" do
            expect(response).to render_template("admin/petitions/show")
          end

          it "hasn't removed the petition" do
            expect(petition).not_to be_removed
          end
        end

        context "and the params are valid" do
          let :params do
            { reason_for_removal: "Removed at the request of the creator" }
          end

          it "redirects to the petition show page" do
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
          end

          it "sets the flash notice message" do
            expect(flash[:notice]).to eq("Petition has been successfully updated")
          end

          it "has removed the petition" do
            expect(petition).to be_removed
          end
        end
      end
    end
  end
end
