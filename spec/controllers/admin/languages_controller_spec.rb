require 'rails_helper'

RSpec.describe Admin::LanguagesController, type: :controller, admin: true do
  let!(:language) { FactoryBot.create(:language, :english) }

  before do
    allow(Language).to receive(:find_by!).with(locale: "en-GB").and_return(language)
  end

  context "when not logged in" do

    [
      ["GET", "/admin/languages", :index, {}, nil],
      ["GET", "/admin/languages/en-GB", :show, { locale: "en-GB" }, nil],
      ["GET", "/admin/languages/en-GB.yml", :show, { locale: "en-GB" }, :yaml],
      ["GET", "/admin/languages/en-GB/title", :edit, { locale: "en-GB", key: "title" }, nil],
      ["PATCH", "/admin/languages/en-GB/title", :update, { locale: "en-GB", key: "title" }, nil],
      ["DELETE", "/admin/languages/en-GB/title", :destroy, { locale: "en-GB", key: "title" }, nil],
      ["POST", "/admin/languages/en-GB/reload", :reload, { locale: "en-GB" }, nil]
    ].each do |method, path, action, params, format|

      describe "#{method} #{path}" do
        before { process action, method: method, params: params, as: format }

        it "redirects to the login page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
        end
      end

    end
  end

  context "when logged in as a moderator" do
    let(:moderator) { FactoryBot.create(:moderator_user) }
    before { login_as(moderator) }

    [
      ["GET", "/admin/languages", :index, {}, nil],
      ["GET", "/admin/languages/en-GB", :show, { locale: "en-GB" }, nil],
      ["GET", "/admin/languages/en-GB.yml", :show, { locale: "en-GB" }, :yaml],
      ["GET", "/admin/languages/en-GB/title", :edit, { locale: "en-GB", key: "title" }, nil],
      ["PATCH", "/admin/languages/en-GB/title", :update, { locale: "en-GB", key: "title" }, nil],
      ["DELETE", "/admin/languages/en-GB/title", :destroy, { locale: "en-GB", key: "title" }, nil],
      ["POST", "/admin/languages/en-GB/reload", :reload, { locale: "en-GB" }, nil]
    ].each do |method, path, action, params, format|

      describe "#{method} #{path}" do
        before { process action, method: method, params: params, as: format }

        it "redirects to the admin hub page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin")
        end
      end

    end
  end

  context "when logged in as a sysadmin" do
    let(:sysadmin) { FactoryBot.create(:sysadmin_user) }
    before { login_as(sysadmin) }

    describe "GET /admin/languages" do
      before { get :index }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :index template" do
        expect(response).to render_template("admin/languages/index")
      end
    end

    describe "GET /admin/languages/en-GB" do
      before { get :show, params: { locale: "en-GB" } }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :show template" do
        expect(response).to render_template("admin/languages/show")
      end
    end

    describe "GET /admin/languages/en-GB.yml" do
      before { get :show, params: { locale: "en-GB" }, as: :yaml }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :show template" do
        expect(response).to render_template("admin/languages/show")
      end

      it "sets the content type" do
        expect(response["Content-Type"]).to eq("application/x-yaml; charset=utf-8")
      end

      it "sets the content disposition" do
        expect(response["Content-Disposition"]).to eq("attachment; filename=ui.en-GB.yml")
      end
    end

    describe "GET /admin/languages/en-GB/title" do
      before { get :edit, params: { locale: "en-GB", key: "title" } }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :edit template" do
        expect(response).to render_template("admin/languages/edit")
      end
    end

    describe "PATCH /admin/languages/en-GB/title" do
      context "when the update is successful" do
        before { patch :update, params: { locale: "en-GB", key: "title", translation: "Welsh Petitions" } }

        it "redirects to the show page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/languages/en-GB/title")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Translation updated successfully")
        end
      end

      context "when the update is unsuccessful" do
        before do
          expect(language).to receive(:set!).with("title", "Welsh Petitions").and_return(false)
        end

        before { patch :update, params: { locale: "en-GB", key: "title", translation: "Welsh Petitions" } }

        it "renders the :edit template" do
          expect(response).to render_template("admin/languages/edit")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Translation could not be updated - please contact support")
        end
      end
    end

    describe "DELETE /admin/languages/en-GB/title" do
      context "when the deletion is successful" do
        before { delete :destroy, params: { locale: "en-GB", key: "title" } }

        it "redirects to the show page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/languages/en-GB")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Translation deleted successfully")
        end
      end

      context "when the deletion is unsuccessful" do
        before do
          expect(language).to receive(:delete!).with("title").and_return(false)
        end

        before { delete :destroy, params: { locale: "en-GB", key: "title" } }

        it "redirects to the show page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/languages/en-GB")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Translation not deleted - please contact support")
        end
      end
    end

    describe "POST /admin/languages/en-GB/reload" do
      context "when the reload is successful" do
        before { post :reload, params: { locale: "en-GB" } }

        it "redirects to the show page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/languages")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Translations reloaded successfully")
        end
      end

      context "when the reload is unsuccessful" do
        before do
          expect(language).to receive(:reload_translations).and_return(false)
        end

        before { post :reload, params: { locale: "en-GB" } }

        it "redirects to the show page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/languages")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Translations could not be reloaded - please contact support")
        end
      end
    end
  end
end
