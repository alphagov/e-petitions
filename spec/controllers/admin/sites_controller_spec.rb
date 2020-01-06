require 'rails_helper'

RSpec.describe Admin::SitesController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/site/edit", :edit, {}],
      ["PATCH", "/admin/site", :update, {}]
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
      ["GET", "/admin/site/edit", :edit, {}],
      ["PATCH", "/admin/site", :update, {}]
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

    describe "GET /admin/site/edit" do
      before { get :edit }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :edit template" do
        expect(response).to render_template("admin/sites/edit")
      end
    end

    describe "PATCH /admin/site" do
      before { patch :update, params: { site: params } }

      context "when the params are invalid" do
        let :params do
          { title: "" }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :edit template" do
          expect(response).to render_template("admin/sites/edit")
        end
      end

      context "when the params are valid" do
        let :params do
          { title: "Petition parliament" }
        end

        it "redirects to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/site/edit")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Site updated successfully")
        end
      end

      context "when submitting just the petitions params" do
        let :params do
          { petition_duration: "6", threshold_for_response: "10000", threshold_for_debate: "100000" }
        end

        it "redirects to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/site/edit")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Site updated successfully")
        end
      end

      context "when submitting just the moderation params" do
        let :params do
          { threshold_for_moderation: "5", minimum_number_of_sponsors: "5", maximum_number_of_sponsors: "20" }
        end

        it "redirects to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/site/edit")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Site updated successfully")
        end
      end

      context "when submitting just the access params" do
        let :params do
          { enabled: "true", protected: "false", login_timeout: "3600" }
        end

        it "redirects to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/site/edit")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Site updated successfully")
        end
      end
    end
  end
end
