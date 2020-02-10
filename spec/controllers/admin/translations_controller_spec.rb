require 'rails_helper'

RSpec.describe Admin::TranslationsController, type: :controller, admin: true do
  shared_examples_for "a translations controller" do
    context "and the Origin header is not set" do
      describe "GET /admin/translations" do
        it "raises a CORS exception" do
          expect {
            get :index
          }.to raise_error(
            ActionController::InvalidCrossOriginRequest
          )
        end
      end
    end

    context "and the Origin header is set to an incorrect value" do
      before do
        request.set_header "HTTP_ORIGIN", "https://example.com"
      end

      describe "GET /admin/translations" do
        it "raises a CORS exception" do
          expect {
            get :index
          }.to raise_error(
            ActionController::InvalidCrossOriginRequest
          )
        end
      end
    end

    context "and the Origin header is set to the english domain" do
      before do
        request.set_header "HTTP_ORIGIN", "https://petition.parliament.wales"
      end

      describe "GET /admin/translations" do
        it "raises an exception for HTML requests" do
          expect {
            get :index, as: :html
          }.to raise_error(
            ActionController::UnknownFormat
          )
        end

        it "doesn't raise an exception for JS requests" do
          expect {
            get :index, as: :js
          }.not_to raise_error
        end


        it "sets the cache control header to 'no-cache, no-store'" do
          get :index, as: :js

          expect(response.status).to eq(200)
          expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")
        end

        it "sets the CORS headers correctly" do
          get :index, as: :js

          expect(response.status).to eq(200)
          expect(response.headers["Access-Control-Allow-Origin"]).to eq("https://petition.parliament.wales")
          expect(response.headers["Access-Control-Allow-Methods"]).to eq("GET")
          expect(response.headers["Access-Control-Allow-Headers"]).to eq("Origin, X-Requested-With, Content-Type, Accept")
          expect(response.headers["Access-Control-Allow-Credentials"]).to eq("true")
          expect(response.headers["Vary"]).to eq("Origin")
        end
      end
    end

    context "and the Origin header is set to the welsh domain" do
      before do
        request.set_header "HTTP_ORIGIN", "https://deiseb.senedd.cymru"
      end

      describe "GET /admin/translations" do
        it "raises an exception for HTML requests" do
          expect {
            get :index, as: :html
          }.to raise_error(
            ActionController::UnknownFormat
          )
        end

        it "doesn't raise an exception for JS requests" do
          expect {
            get :index, as: :js
          }.not_to raise_error
        end

        it "sets the cache control header to 'no-cache, no-store'" do
          get :index, as: :js

          expect(response.status).to eq(200)
          expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")
        end

        it "sets the CORS headers correctly" do
          get :index, as: :js

          expect(response.status).to eq(200)
          expect(response.headers["Access-Control-Allow-Origin"]).to eq("https://deiseb.senedd.cymru")
          expect(response.headers["Access-Control-Allow-Methods"]).to eq("GET")
          expect(response.headers["Access-Control-Allow-Headers"]).to eq("Origin, X-Requested-With, Content-Type, Accept")
          expect(response.headers["Access-Control-Allow-Credentials"]).to eq("true")
          expect(response.headers["Vary"]).to eq("Origin")
        end
      end
    end
  end

  context "when not logged in" do
    it_behaves_like "a translations controller"
  end

  context "when logged in as a moderator" do
    let(:moderator) { FactoryBot.create(:moderator_user) }
    before { login_as(moderator) }

    it_behaves_like "a translations controller"
  end

  context "when logged in as a sysadmin" do
    let(:sysadmin) { FactoryBot.create(:sysadmin_user) }
    before { login_as(sysadmin) }

    it_behaves_like "a translations controller"
  end
end
