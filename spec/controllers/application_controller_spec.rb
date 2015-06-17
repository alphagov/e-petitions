require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render text: 'OK'
    end
  end

  it "reloads the site instance on every request" do
    expect(Site).to receive(:reload)
    get :index
  end

  context "when the site is disabled" do
    before do
      expect(Site).to receive(:enabled?).and_return(false)
    end

    it "raises a Site::ServiceUnavailable error" do
      expect { get :index }.to raise_error(Site::ServiceUnavailable)
    end
  end

  context "when the site is protected" do
    context "and the request is local" do
      before do
        expect(request).to receive(:local?).and_return(true)
        expect(Site).not_to receive(:protected?)
      end

      it "does not request authentication" do
        get :index
        expect(response).to have_http_status(200)
      end
    end

    context "and the request is not local" do
      before do
        expect(request).to receive(:local?).and_return(false)
        expect(Site).to receive(:protected?).and_return(true)
      end

      it "requests authentication" do
        get :index
        expect(response).to have_http_status(401)
      end
    end

    context "and the request is authenticated" do
      before do
        http_authentication "username", "password"

        expect(request).to receive(:local?).and_return(false)
        expect(Site).to receive(:protected?).and_return(true)
        expect(Site).to receive(:authenticate).with("username", "password").and_return(true)
      end

      it "responds with 200 OK" do
        get :index
        expect(response).to have_http_status(200)
      end
    end
  end
end
