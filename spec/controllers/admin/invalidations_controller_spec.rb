require 'rails_helper'

RSpec.describe Admin::InvalidationsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/invalidations", :index, {}],
      ["GET", "/admin/invalidations", :new, {}],
      ["POST", "/admin/invalidations", :create, {}],
      ["GET", "/admin/invalidations/:id/edit", :edit, { id: 1 }],
      ["PATCH", "/admin/invalidations/:id", :update, { id: 1 }],
      ["DELETE", "/admin/invalidations/:id", :destroy, { id: 1 }],
      ["POST", "/admin/invalidations/:id/cancel", :cancel, { id: 1 }],
      ["POST", "/admin/invalidations/:id/count", :count, { id: 1 }],
      ["POST", "/admin/invalidations/:id/start", :start, { id: 1 }]
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
      ["GET", "/admin/invalidations", :index, {}],
      ["GET", "/admin/invalidations", :new, {}],
      ["POST", "/admin/invalidations", :create, {}],
      ["GET", "/admin/invalidations/:id/edit", :edit, { id: 1 }],
      ["PATCH", "/admin/invalidations/:id", :update, { id: 1 }],
      ["DELETE", "/admin/invalidations/:id", :destroy, { id: 1 }],
      ["POST", "/admin/invalidations/:id/cancel", :cancel, { id: 1 }],
      ["POST", "/admin/invalidations/:id/count", :count, { id: 1 }],
      ["POST", "/admin/invalidations/:id/start", :start, { id: 1 }]
    ].each do |method, path, action, params|

      describe "#{method} #{path}" do
        before { process action, method, params }

        it "redirects to the login page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin")
        end
      end

    end
  end

  context "when logged in as a sysadmin" do
    let(:sysadmin) { FactoryGirl.create(:sysadmin_user) }
    before { login_as(sysadmin) }

    describe "GET /admin/invalidations" do
      before { get :index }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :index template" do
        expect(response).to render_template("admin/invalidations/index")
      end
    end

    describe "GET /admin/invalidations/new" do
      before { get :new }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :new template" do
        expect(response).to render_template("admin/invalidations/new")
      end
    end

    describe "POST /admin/invalidations" do
      before { post :create, invalidation: params }

      context "with invalid params" do
        let :params do
          { summary: "Invalidate some signatures" }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :new template" do
          expect(response).to render_template("admin/invalidations/new")
        end
      end

      context "with valid params" do
        let :params do
          { summary: "Invalidate some signatures", email: "user@example.com" }
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Invalidation created successfully")
        end
      end
    end

    describe "GET /admin/invalidations/:id/edit" do
      before { get :edit, id: invalidation.id }

      context "when the invalidation is still pending" do
        let(:invalidation) { FactoryGirl.create(:invalidation, email: "user@example.com") }

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :edit template" do
          expect(response).to render_template("admin/invalidations/edit")
        end
      end

      context "when the invalidation is not pending" do
        let(:invalidation) { FactoryGirl.create(:invalidation, :completed, email: "user@example.com") }

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Can't edit invalidations that aren't pending")
        end
      end
    end

    describe "PATCH /admin/invalidations/:id" do
      before { patch :update, id: invalidation.id, invalidation: params }

      context "when the invalidation is still pending" do
        let(:invalidation) { FactoryGirl.create(:invalidation, email: "user@example.com") }

        context "and the params are invalid" do
          let :params do
            { summary: "Invalidate some signatures", email: "" }
          end

          it "returns 200 OK" do
            expect(response).to have_http_status(:ok)
          end

          it "renders the :edit template" do
            expect(response).to render_template("admin/invalidations/edit")
          end
        end

        context "and the params are valid" do
          let :params do
            { summary: "Invalidate some signatures", email: "user@example.com" }
          end

          it "redirects to the index page" do
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
          end

          it "sets the flash notice message" do
            expect(flash[:notice]).to eq("Invalidation updated successfully")
          end
        end
      end

      context "when the invalidation is not pending" do
        let(:invalidation) { FactoryGirl.create(:invalidation, :completed, email: "user@example.com") }

        let :params do
          { summary: "Invalidate some signatures", email: "user@example.com" }
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Can't edit invalidations that aren't pending")
        end
      end
    end

    describe "DELETE /admin/invalidations/:id" do
      context "when the invalidation is still pending" do
        let(:invalidation) { FactoryGirl.create(:invalidation, email: "user@example.com") }

        before { delete :destroy, id: invalidation.id }

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Invalidation removed successfully")
        end
      end

      context "when the invalidation is cancelled, but not started" do
        let(:invalidation) { FactoryGirl.create(:invalidation, :cancelled, email: "user@example.com") }

        before { delete :destroy, id: invalidation.id }

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Invalidation removed successfully")
        end
      end

      context "when the invalidation is not pending" do
        let(:invalidation) { FactoryGirl.create(:invalidation, :started, email: "user@example.com") }

        before { delete :destroy, id: invalidation.id }

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Can't remove invalidations that have started")
        end
      end

      context "when the destroy fails for an unknown reason" do
        let(:invalidation) { FactoryGirl.create(:invalidation, email: "user@example.com") }
        let(:id) { invalidation.id.to_s }

        before do
          expect(Invalidation).to receive(:find).with(id).and_return(invalidation)
          expect(invalidation).to receive(:destroy).and_return(false)
          delete :destroy, id: invalidation.id
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Invalidation could not be removed - please contact support")
        end
      end
    end

    describe "POST /admin/invalidations/:id/cancel" do
      context "when the invalidation has not completed" do
        let(:invalidation) { FactoryGirl.create(:invalidation, :started, email: "user@example.com") }

        before { post :cancel, id: invalidation.id }

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Invalidation cancelled successfully")
        end
      end

      context "when the invalidation has completed" do
        let(:invalidation) { FactoryGirl.create(:invalidation, :completed, email: "user@example.com") }

        before { post :cancel, id: invalidation.id }

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Can't cancel invalidations that have completed")
        end
      end

      context "when the cancel fails for an unknown reason" do
        let(:invalidation) { FactoryGirl.create(:invalidation, email: "user@example.com") }
        let(:id) { invalidation.id.to_s }

        before do
          expect(Invalidation).to receive(:find).with(id).and_return(invalidation)
          expect(invalidation).to receive(:cancel!).and_return(false)
          post :cancel, id: invalidation.id
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Invalidation could not be cancelled - please contact support")
        end
      end
    end

    describe "POST /admin/invalidations/:id/count" do
      context "when the invalidation is still pending" do
        let(:invalidation) { FactoryGirl.create(:invalidation, email: "user@example.com") }

        before { post :count, id: invalidation.id }

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to match(/\ACounted the matching signatures for invalidation/)
        end
      end

      context "when the invalidation is no longer pending" do
        let(:invalidation) { FactoryGirl.create(:invalidation, :started, email: "user@example.com") }

        before { post :count, id: invalidation.id }

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Can't count invalidations that aren't pending")
        end
      end

      context "when the count fails for an unknown reason" do
        let(:invalidation) { FactoryGirl.create(:invalidation, email: "user@example.com") }
        let(:id) { invalidation.id.to_s }

        before do
          expect(Invalidation).to receive(:find).with(id).and_return(invalidation)
          expect(invalidation).to receive(:count!).and_return(false)
          post :count, id: invalidation.id
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Invalidation could not be counted - please contact support")
        end
      end
    end

    describe "POST /admin/invalidations/:id/start" do
      context "when the invalidation is still pending" do
        let(:invalidation) { FactoryGirl.create(:invalidation, email: "user@example.com") }

        before { post :start, id: invalidation.id }

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to match(/\AEnqueued the invalidation/)
        end
      end

      context "when the invalidation is no longer pending" do
        let(:invalidation) { FactoryGirl.create(:invalidation, :started, email: "user@example.com") }

        before { post :start, id: invalidation.id }

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Can't start invalidations that aren't pending")
        end
      end

      context "when the start fails for an unknown reason" do
        let(:invalidation) { FactoryGirl.create(:invalidation, email: "user@example.com") }
        let(:id) { invalidation.id.to_s }

        before do
          expect(Invalidation).to receive(:find).with(id).and_return(invalidation)
          expect(invalidation).to receive(:start!).and_return(false)
          post :start, id: invalidation.id
        end

        it "redirects to the index page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/invalidations")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Invalidation could not be enqueued - please contact support")
        end
      end
    end
  end
end
