require 'rails_helper'

RSpec.describe Admin::Archived::PetitionRemovalsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/archived/petitions/:petition_id/removal", :show, { petition_id: 1 }],
      ["PATCH", "/admin/archived/petitions/:petition_id/removal", :update, { petition_id: 1 }],
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
      ["GET", "/admin/archived/petitions/:petition_id/removal", :show, { petition_id: 1 }],
      ["PATCH", "/admin/archived/petitions/:petition_id/removal", :update, { petition_id: 1 }],
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
    before { allow(Archived::Petition).to receive(:find).with(petition.to_param).and_return(petition) }

    describe "GET /admin/petitions/:petition_id/removal" do
      before { get :show, params: { petition_id: petition.id } }

      context "when the petition has been removed" do
        let(:petition) { FactoryBot.create(:archived_petition, :removed) }

        it "redirects to the petition show page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Petition has already been removed")
        end
      end

      context "when the petition has not been removed" do
        let(:petition) { FactoryBot.create(:archived_petition) }

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :show template" do
          expect(response).to render_template("admin/archived/petitions/show")
        end
      end
    end

    describe "PATCH /admin/archived/petitions/:petition_id/removal" do
      context "when the petition has been removed" do
        let(:petition) { FactoryBot.create(:archived_petition, :removed) }

        before { patch :update, params: { petition_id: petition.id } }

        it "redirects to the archived petition show page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Petition has already been removed")
        end
      end

      context "when the petition has not been removed" do
        let(:petition) { FactoryBot.create(:archived_petition) }

        context "and the update fails" do
          before do
            expect(Archived::Petition).to receive(:find).with(petition.to_param).and_return(petition)
            expect(petition).to receive(:remove).and_return(false)

            patch :update, params: { petition_id: petition.id }
          end

          it "redirects to the archived petition removal page" do
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}/removal")
          end

          it "sets the flash alert message" do
            expect(flash[:alert]).to eq("Petition could not be updated - please contact support")
          end

          it "hasn't removed the petition" do
            expect(petition).not_to be_removed
          end
        end

        context "and the update succeeds" do
          before do
            expect(Archived::Petition).to receive(:find).with(petition.to_param).and_return(petition)
            expect(petition).to receive(:remove).and_call_original

            patch :update, params: { petition_id: petition.id }
          end

          it "redirects to the petition show page" do
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}")
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
