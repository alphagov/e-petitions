require 'rails_helper'

RSpec.describe Admin::TopicsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/topics", :index, {}],
      ["GET", "/admin/topics/new", :new, {}],
      ["POST", "/admin/topics", :create, {}],
      ["GET", "/admin/topics/:id/edit", :edit, { id: 1 }],
      ["PATCH", "/admin/topics/:id", :update, { id: 1 }],
      ["DELETE", "/admin/topics/:id", :destroy, { id: 1 }]
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
      ["GET", "/admin/topics", :index, {}],
      ["GET", "/admin/topics/new", :new, {}],
      ["POST", "/admin/topics", :create, {}],
      ["GET", "/admin/topics/:id/edit", :edit, { id: 1 }],
      ["PATCH", "/admin/topics/:id", :update, { id: 1 }],
      ["DELETE", "/admin/topics/:id", :destroy, { id: 1 }]
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

    describe "GET /admin/topics" do
      before { get :index }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :index template" do
        expect(response).to render_template("admin/topics/index")
      end
    end

    describe "GET /admin/topics/new" do
      before { get :new }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :new template" do
        expect(response).to render_template("admin/topics/new")
      end
    end

    describe "POST /admin/topics" do
      before { post :create, params: { topic: params } }

      context "with invalid params" do
        let :params do
          { code: "", name: "" }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :new template" do
          expect(response).to render_template("admin/topics/new")
        end
      end

      context "with valid params" do
        let :params do
          { code: "topic", name: "Topic" }
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/topics")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Topic created successfully")
        end
      end
    end

    describe "GET /admin/topics/:id/edit" do
      let(:topic) { FactoryBot.create(:topic) }

      before { get :edit, params: { id: topic.id } }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :edit template" do
        expect(response).to render_template("admin/topics/edit")
      end
    end

    describe "PATCH /admin/topics/:id" do
      let(:topic) { FactoryBot.create(:topic) }

      before { patch :update, params: { id: topic.id, topic: params } }

      context "and the params are invalid" do
        let :params do
          { code: "", name: "" }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :edit template" do
          expect(response).to render_template("admin/topics/edit")
        end
      end

      context "and the params are valid" do
        let :params do
          { code: "topic", name: "Topic" }
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/topics")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Topic updated successfully")
        end
      end
    end

    describe "DELETE /admin/topics/:id" do
      let(:topic) { FactoryBot.create(:topic) }

      before { delete :destroy, params: { id: topic.id } }

      it "redirects to the index page" do
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/topics")
      end

      it "sets the flash notice message" do
        expect(flash[:notice]).to eq("Topic removed successfully")
      end
    end
  end
end
