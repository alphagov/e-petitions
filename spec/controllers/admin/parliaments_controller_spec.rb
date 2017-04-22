require 'rails_helper'

RSpec.describe Admin::ParliamentsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/parliament", :show, {}],
      ["PATCH", "/admin/parliament", :update, {}]
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
      ["GET", "/admin/parliament", :show, {}],
      ["PATCH", "/admin/parliament", :update, {}]
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

    describe "GET /admin/parliament" do
      before { get :show }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :show template" do
        expect(response).to render_template("admin/parliaments/show")
      end
    end

    describe "PATCH /admin/parliament" do
      before { patch :update, parliament: params }

      let(:parliament) { FactoryGirl.create(:parliament) }

      context "and the params are invalid" do
        let :params do
          {
            dissolution_at: 2.weeks.from_now.iso8601,
            dissolution_heading: "",
            dissolution_message: ""
          }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :show template" do
          expect(response).to render_template("admin/parliaments/show")
        end
      end

      context "and the params are valid" do
        let :params do
          {
            dissolution_at: 2.weeks.from_now.iso8601,
            dissolution_heading: "Parliament is dissolving",
            dissolution_message: "This means all petitions will close in 2 weeks"
          }
        end

        it "redirects to the admin dashboard page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Parliament updated successfully")
        end
      end
    end
  end
end
