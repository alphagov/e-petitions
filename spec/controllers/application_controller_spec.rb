require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    before_action :do_not_cache

    def index
      render text: 'OK'
    end
  end

  let(:cache_control) { response.headers['Cache-Control'] }

  it "reloads the site instance on every request" do
    expect(Site).to receive(:reload)
    get :index
  end

  it "sets cache control headers when asked" do
    get :index
    expect(cache_control).to eq('no-store, no-cache')
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

  context '#public_petition_facets' do
    it 'extracts the list of public facets from the locale file' do
      expect(controller.send(:public_petition_facets)).to eq I18n.t(:"petitions.facets.public")
    end

    it 'is a helper method' do
      expect(controller.class.helpers).to respond_to :public_petition_facets
    end
  end
end
