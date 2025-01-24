require 'rails_helper'

RSpec.describe Admin::PagesController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/pages", :index, {}],
      ["GET", "/admin/pages/:slug/edit", :edit, { slug: "help" }],
      ["PATCH", "/admin/pages/:id", :update, { slug: "help" }]
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
      ["GET", "/admin/pages", :index, {}],
      ["GET", "/admin/pages/:slug/edit", :edit, { slug: "help" }],
      ["PATCH", "/admin/pages/:id", :update, { slug: "help" }]
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

    describe "GET /admin/pages" do
      before { get :index }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :index template" do
        expect(response).to render_template("admin/pages/index")
      end
    end

    describe "GET /admin/pages/:slug/edit" do
      let(:page) { FactoryBot.create(:page) }

      before { get :edit, params: { slug: page.slug } }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :edit template" do
        expect(response).to render_template("admin/pages/edit")
      end
    end

    describe "PATCH /admin/pages/:slug" do
      let(:page) { FactoryBot.create(:page) }

      before { patch :update, params: { slug: page.slug, page: params } }

      context "and the params are invalid" do
        let :params do
          { title: "" }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :edit template" do
          expect(response).to render_template("admin/pages/edit")
        end
      end

      context "and the params are valid" do
        let :params do
          { title: "How petitions work", content: "# How petitions work" }
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/pages")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Page updated successfully")
        end
      end
    end
  end
end
