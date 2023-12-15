require 'rails_helper'

RSpec.describe Admin::LocksController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/petitions/:petition_id/lock.json", :show, { petition_id: "100000" }],
      ["POST", "/admin/petitions/:petition_id/lock.json", :create, { petition_id: "100000" }],
      ["PATCH", "/admin/petitions/:petition_id/lock.json", :update, { petition_id: "100000" }],
      ["DELETE", "/admin/petitions/:petition_id/lock.json", :destroy, { petition_id: "100000" }]
    ].each do |method, path, action, params|

      describe "#{method} #{path}" do
        before { process action, method: method, params: params, format: :json }

        it "redirects to the login page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
        end
      end

    end
  end

  context "when logged in as a moderator" do
    let(:moderator) { FactoryBot.create(:moderator_user) }
    let(:petition) { FactoryBot.create(:petition) }

    before { login_as(moderator) }

    describe "GET /admin/petitions/:petition_id/lock.json" do
      it "returns 200 OK" do
        get :show, params: { petition_id: petition.to_param }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "renders the :show template" do
        get :show, params: { petition_id: petition.to_param }, format: :json
        expect(response).to render_template("admin/locks/show")
      end

      context "when the petition is locked by the moderator" do
        let(:petition) { FactoryBot.create(:petition, locked_by: moderator, locked_at: 1.hour.ago) }

        it "updates the locked_at timestamp" do
          expect {
            get :show, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_at
          }.to be_within(1.second).of(Time.current)
        end
      end

      context "when the petition is locked by someone else" do
        let(:other_user) { FactoryBot.create(:moderator_user) }
        let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

        it "doesn't update the locked_at timestamp" do
          expect {
            get :show, params: { petition_id: petition.to_param }, format: :json
          }.not_to change {
            petition.reload.locked_at
          }
        end
      end
    end

    describe "POST /admin/petitions/:petition_id/lock.json" do
      it "returns 200 OK" do
        get :create, params: { petition_id: petition.to_param }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "renders the :create template" do
        get :create, params: { petition_id: petition.to_param }, format: :json
        expect(response).to render_template("admin/locks/create")
      end

      context "when the petition is unlocked" do
        let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

        it "updates the locked_by association" do
          expect {
            get :create, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_by
          }.from(nil).to eq(moderator)
        end

        it "updates the locked_at timestamp" do
          expect {
            get :create, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_at
          }.from(nil).to be_within(1.second).of(Time.current)
        end
      end

      context "when the petition is locked by the moderator" do
        let(:petition) { FactoryBot.create(:petition, locked_by: moderator, locked_at: 1.hour.ago) }

        it "doesn't update the locked_by association" do
          expect {
            get :create, params: { petition_id: petition.to_param }, format: :json
          }.not_to change {
            petition.reload.locked_by
          }
        end

        it "updates the locked_at timestamp" do
          expect {
            get :create, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_at
          }.to be_within(1.second).of(Time.current)
        end
      end

      context "when the petition is locked by someone else" do
        let(:other_user) { FactoryBot.create(:moderator_user) }
        let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

        it "doesn't update the locked_by association" do
          expect {
            get :create, params: { petition_id: petition.to_param }, format: :json
          }.not_to change {
            petition.reload.locked_by
          }
        end

        it "doesn't update the locked_at timestamp" do
          expect {
            get :create, params: { petition_id: petition.to_param }, format: :json
          }.not_to change {
            petition.reload.locked_at
          }
        end
      end
    end

    describe "PATCH /admin/petitions/:petition_id/lock.json" do
      it "returns 200 OK" do
        get :update, params: { petition_id: petition.to_param }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "renders the :update template" do
        get :update, params: { petition_id: petition.to_param }, format: :json
        expect(response).to render_template("admin/locks/update")
      end

      context "when the petition is unlocked" do
        let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

        it "updates the locked_by association" do
          expect {
            get :update, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_by
          }.from(nil).to eq(moderator)
        end

        it "updates the locked_at timestamp" do
          expect {
            get :update, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_at
          }.from(nil).to be_within(1.second).of(Time.current)
        end
      end

      context "when the petition is locked by the moderator" do
        let(:petition) { FactoryBot.create(:petition, locked_by: moderator, locked_at: 1.hour.ago) }

        it "doesn't update the locked_by association" do
          expect {
            get :update, params: { petition_id: petition.to_param }, format: :json
          }.not_to change {
            petition.reload.locked_by
          }
        end

        it "updates the locked_at timestamp" do
          expect {
            get :update, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_at
          }.to be_within(1.second).of(Time.current)
        end
      end

      context "when the petition is locked by someone else" do
        let(:other_user) { FactoryBot.create(:moderator_user) }
        let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

        it "updates the locked_by association" do
          expect {
            get :update, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_by
          }.from(other_user).to eq(moderator)
        end

        it "updates the locked_at timestamp" do
          expect {
            get :update, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_at
          }.to be_within(1.second).of(Time.current)
        end
      end
    end

    describe "DELETE /admin/petitions/:petition_id/lock.json" do
      it "returns 200 OK" do
        get :destroy, params: { petition_id: petition.to_param }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it "renders the :destroy template" do
        get :destroy, params: { petition_id: petition.to_param }, format: :json
        expect(response).to render_template("admin/locks/destroy")
      end

      context "when the petition is unlocked" do
        let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

        it "doesn't update the locked_by association" do
          expect {
            get :destroy, params: { petition_id: petition.to_param }, format: :json
          }.not_to change {
            petition.reload.locked_by
          }
        end

        it "doesn't update the locked_at timestamp" do
          expect {
            get :destroy, params: { petition_id: petition.to_param }, format: :json
          }.not_to change {
            petition.reload.locked_at
          }
        end
      end

      context "when the petition is locked by the moderator" do
        let(:petition) { FactoryBot.create(:petition, locked_by: moderator, locked_at: 1.hour.ago) }

        it "updates the locked_by association" do
          expect {
            get :destroy, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_by
          }.from(moderator).to(nil)
        end

        it "updates the locked_at timestamp" do
          expect {
            get :destroy, params: { petition_id: petition.to_param }, format: :json
          }.to change {
            petition.reload.locked_at
          }.to be_nil
        end
      end

      context "when the petition is locked by someone else" do
        let(:other_user) { FactoryBot.create(:moderator_user) }
        let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

        it "doesn't update the locked_by association" do
          expect {
            get :destroy, params: { petition_id: petition.to_param }, format: :json
          }.not_to change {
            petition.reload.locked_by
          }
        end

        it "doesn't update the locked_at timestamp" do
          expect {
            get :destroy, params: { petition_id: petition.to_param }, format: :json
          }.not_to change {
            petition.reload.locked_at
          }
        end
      end
    end
  end
end
