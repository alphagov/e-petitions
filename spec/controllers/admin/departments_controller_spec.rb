require 'rails_helper'

RSpec.describe Admin::DepartmentsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/departments", :index, {}],
      ["GET", "/admin/departments/new", :new, {}],
      ["POST", "/admin/departments", :create, {}],
      ["GET", "/admin/departments/:id/edit", :edit, { id: 1 }],
      ["PATCH", "/admin/departments/:id", :update, { id: 1 }],
      ["DELETE", "/admin/departments/:id", :destroy, { id: 1 }]
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
      ["GET", "/admin/departments", :index, {}],
      ["GET", "/admin/departments/new", :new, {}],
      ["POST", "/admin/departments", :create, {}],
      ["GET", "/admin/departments/:id/edit", :edit, { id: 1 }],
      ["PATCH", "/admin/departments/:id", :update, { id: 1 }],
      ["DELETE", "/admin/departments/:id", :destroy, { id: 1 }]
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

    describe "GET /admin/departments" do
      before { get :index }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :index template" do
        expect(response).to render_template("admin/departments/index")
      end
    end

    describe "GET /admin/departments/new" do
      before { get :new }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :new template" do
        expect(response).to render_template("admin/departments/new")
      end
    end

    describe "POST /admin/departments" do
      before { post :create, params: { department: params } }

      context "with invalid params" do
        let :params do
          { name: "" }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :new template" do
          expect(response).to render_template("admin/departments/new")
        end
      end

      context "with valid params" do
        let :params do
          { name: "Department" }
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/departments")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Department created successfully")
        end
      end
    end

    describe "GET /admin/departments/:id/edit" do
      let(:department) { FactoryBot.create(:department) }

      before { get :edit, params: { id: department.id } }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :edit template" do
        expect(response).to render_template("admin/departments/edit")
      end
    end

    describe "PATCH /admin/departments/:id" do
      let(:department) { FactoryBot.create(:department) }

      before { patch :update, params: { id: department.id, department: params } }

      context "and the params are invalid" do
        let :params do
          { name: "" }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :edit template" do
          expect(response).to render_template("admin/departments/edit")
        end
      end

      context "and the params are valid" do
        let :params do
          { name: "department" }
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/departments")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Department updated successfully")
        end
      end
    end

    describe "DELETE /admin/departments/:id" do
      let(:department) { FactoryBot.create(:department) }

      before { delete :destroy, params: { id: department.id } }

      it "redirects to the index page" do
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/departments")
      end

      it "sets the flash notice message" do
        expect(flash[:notice]).to eq("Department removed successfully")
      end
    end
  end
end
