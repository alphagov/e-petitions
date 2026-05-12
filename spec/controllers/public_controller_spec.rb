require 'rails_helper'

RSpec.describe PublicController, type: :controller do
  controller do
    before_action :do_not_cache
    before_action :set_cors_headers, if: :json_request?

    def index
      render plain: 'OK'
    end
  end

  context "when the site is disabled" do
    before do
      expect(Site).to receive(:enabled?).and_return(false)
    end

    it "raises a Site::ServiceUnavailable error" do
      expect { get :index }.to raise_error(Site::ServiceUnavailable)
    end

    context "and the request is authenticated" do
      let(:password_digest) { BCrypt::Password.create("password") }
      let(:login_digest) { Digest::SHA256.base64digest("username:#{password_digest}") }

      before do
        cookies[:login] = login_digest
        request.env["REMOTE_ADDR"] = "0.0.0.0"

        expect(Site).to receive(:protected?).and_return(true)
        expect(Site).to receive(:login_digest).twice.and_return(login_digest)
      end

      it "responds with 200 OK" do
        get :index
        expect(response).to have_http_status(200)
      end
    end
  end

  context "when the site is protected" do
    context "and the request is local" do
      before do
        request.env["REMOTE_ADDR"] = "127.0.0.1"
        expect(Site).not_to receive(:protected?)
      end

      it "does not redirect to the login page" do
        get :index
        expect(response).to have_http_status(200)
      end
    end

    context "and the request is not local" do
      before do
        request.env["REMOTE_ADDR"] = "0.0.0.0"
        expect(Site).to receive(:protected?).and_return(true)
      end

      context "and the request is a HTML request" do
        it "redirects to the login page" do
          get :index
          expect(response).to redirect_to("https://petition.parliament.uk/login")
        end
      end

      context "and the request is a JSON request" do
        it "responds with 403 Forbidden" do
          get :index, as: :json
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "and the request is authenticated" do
      let(:password_digest) { BCrypt::Password.create("password") }
      let(:login_digest) { Digest::SHA256.base64digest("username:#{password_digest}") }

      before do
        cookies[:login] = login_digest
        request.env["REMOTE_ADDR"] = "0.0.0.0"

        expect(Site).to receive(:protected?).and_return(true)
        expect(Site).to receive(:login_digest).and_return(login_digest)
      end

      it "responds with 200 OK" do
        get :index
        expect(response).to have_http_status(200)
      end
    end
  end

  context '#public_petition_facets' do
    it 'extracts the list of public facets from the locale file' do
      expect(controller.send(:public_petition_facets)).to eq I18n.t(:"petitions.facets.public")
    end

    it 'is a helper method' do
      expect(controller.class.helpers).to respond_to :public_petition_facets
    end
  end
end
