require 'rails_helper'

RSpec.describe Admin::TagsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/tags", :index, {}],
      ["GET", "/admin/tags/new", :new, {}],
      ["POST", "/admin/tags", :create, {}],
      ["GET", "/admin/tags/:id/edit", :edit, { id: 1 }],
      ["PATCH", "/admin/tags/:id", :update, { id: 1 }],
      ["DELETE", "/admin/tags/:id", :destroy, { id: 1 }]
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
      ["GET", "/admin/tags", :index, {}],
      ["GET", "/admin/tags/new", :new, {}],
      ["POST", "/admin/tags", :create, {}],
      ["GET", "/admin/tags/:id/edit", :edit, { id: 1 }],
      ["PATCH", "/admin/tags/:id", :update, { id: 1 }],
      ["DELETE", "/admin/tags/:id", :destroy, { id: 1 }]
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

    describe "GET /admin/tags" do
      before { get :index }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :index template" do
        expect(response).to render_template("admin/tags/index")
      end
    end

    describe "GET /admin/tags/new" do
      before { get :new }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :new template" do
        expect(response).to render_template("admin/tags/new")
      end
    end

    describe "POST /admin/tags" do
      before { post :create, params: { tag: params } }

      context "with invalid params" do
        let :params do
          { name: "" }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :new template" do
          expect(response).to render_template("admin/tags/new")
        end
      end

      context "with valid params" do
        let :params do
          { name: "Tag" }
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/tags")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Tag created successfully")
        end
      end
    end

    describe "GET /admin/tags/:id/edit" do
      let(:tag) { FactoryBot.create(:tag) }

      before { get :edit, params: { id: tag.id } }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :edit template" do
        expect(response).to render_template("admin/tags/edit")
      end
    end

    describe "PATCH /admin/tags/:id" do
      let(:tag) { FactoryBot.create(:tag) }

      before { patch :update, params: { id: tag.id, tag: params } }

      context "and the params are invalid" do
        let :params do
          { name: "" }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :edit template" do
          expect(response).to render_template("admin/tags/edit")
        end
      end

      context "and the params are valid" do
        let :params do
          { name: "Tag" }
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/tags")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Tag updated successfully")
        end
      end
    end

    describe "DELETE /admin/tags/:id" do
      let(:tag) { FactoryBot.create(:tag) }

      before { delete :destroy, params: { id: tag.id } }

      it "redirects to the index page" do
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/tags")
      end

      it "sets the flash notice message" do
        expect(flash[:notice]).to eq("Tag removed successfully")
      end
    end
  end
end
