require 'rails_helper'

RSpec.describe Admin::SettingsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/settings/edit", :edit, {}],
      ["PATCH", "/admin/settings", :update, {}]
    ].each do |method, path, action, params|

      describe "#{method} #{path}" do
        before { process action, method, params }

        it "redirects to the login page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
        end
      end

    end
  end

  context "when logged in as a moderator" do
    let(:moderator) { FactoryGirl.create(:moderator_user) }
    before { login_as(moderator) }

    [
      ["GET", "/admin/site/edit", :edit, {}],
      ["PATCH", "/admin/site", :update, {}]
    ].each do |method, path, action, params|

      describe "#{method} #{path}" do
        before { process action, method, params }

        it "redirects to the admin hub page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin")
        end
      end

    end
  end

  context "when logged in as a sysadmin" do
    let(:sysadmin) { FactoryGirl.create(:sysadmin_user) }
    before { login_as(sysadmin) }

    describe "GET /admin/settings/edit" do
      before { get :edit }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :edit template" do
        expect(response).to render_template("admin/settings/edit")
      end
    end

    describe "PATCH /admin/settings" do
      before { patch :update, admin_settings: params }

      let :params do
        { petition_tags: ["hello", "world"] }
      end

      it "redirects to the edit page" do
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/settings/edit")
      end

      it "sets the flash notice message" do
        expect(flash[:notice]).to eq("Site settings updated successfully")
      end
    end
  end
end
