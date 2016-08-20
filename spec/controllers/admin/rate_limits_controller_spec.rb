require 'rails_helper'

RSpec.describe Admin::RateLimitsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/rate-limits/edit", :edit, {}],
      ["PATCH", "/admin/rate-limits", :update, {}]
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
      ["GET", "/admin/rate-limits/edit", :edit, {}],
      ["PATCH", "/admin/rate-limits", :update, {}]
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

    describe "GET /admin/rate-limits/edit" do
      before { get :edit }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :edit template" do
        expect(response).to render_template("admin/rate_limits/edit")
      end
    end

    describe "PATCH /admin/rate-limits" do
      before { patch :update, rate_limit: params }

      context "when the params are invalid" do
        let :params do
          { burst_rate: "", burst_period: "", sustained_rate: "", sustained_period: "" }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :edit template" do
          expect(response).to render_template("admin/rate_limits/edit")
        end
      end

      context "when the params are valid" do
        let :params do
          { burst_rate: "1", burst_period: "60", sustained_rate: "5", sustained_period: "300" }
        end

        it "redirects to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/rate-limits/edit")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Rate limits updated successfully")
        end
      end

      context "when submitting just the domain whitelist" do
        let :params do
          { domain_whitelist: "example.com" }
        end

        it "redirects to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/rate-limits/edit")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Rate limits updated successfully")
        end
      end

      context "when submitting just the domain blacklist" do
        let :params do
          { domain_blacklist: "example.com" }
        end

        it "redirects to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/rate-limits/edit")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Rate limits updated successfully")
        end
      end

      context "when submitting just the ip whitelist" do
        let :params do
          { ip_whitelist: "127.0.0.1" }
        end

        it "redirects to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/rate-limits/edit")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Rate limits updated successfully")
        end
      end

      context "when submitting just the ip blacklist" do
        let :params do
          { ip_blacklist: "127.0.0.1" }
        end

        it "redirects to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/rate-limits/edit")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Rate limits updated successfully")
        end
      end

      context "when submitting just the countries list" do
        let :params do
          { countries: "127.0.0.1", geoblocking_enabled: "true" }
        end

        it "redirects to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/rate-limits/edit")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Rate limits updated successfully")
        end
      end
    end
  end
end
