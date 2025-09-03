require 'rails_helper'

RSpec.describe "Requests for apple-touch-icon images", type: :request do
  let(:location) { response.headers["Location"] }
  let(:cache_control) { response.headers["Cache-Control"] }

  describe "GET /apple-touch-icon.png" do
    it "redirects to the generic icon asset" do
      get "/apple-touch-icon.png"

      expect(response).to have_http_status(:temporary_redirect)
      expect(location).to eq "https://petition.parliament.uk/assets/os-social/apple/apple-touch-icon-5820e4ad.png"
      expect(cache_control).to eq "max-age=3600, public"
    end
  end

  describe "GET /apple-touch-icon-precomposed.png" do
    it "redirects to the generic icon asset" do
      get "/apple-touch-icon-precomposed.png"

      expect(response).to have_http_status(:temporary_redirect)
      expect(location).to eq "https://petition.parliament.uk/assets/os-social/apple/apple-touch-icon-5820e4ad.png"
      expect(cache_control).to eq "max-age=3600, public"
    end
  end

  %w[120x120 152x152 167x167 180x180].each do |size|
    describe "GET /apple-touch-icon-#{size}.png" do
      it "redirects to the specific icon asset" do
        get "/apple-touch-icon-#{size}.png"

        expect(response).to have_http_status(:temporary_redirect)
        expect(location).to match %r(https://petition\.parliament\.uk/assets/os-social/apple/apple-touch-icon-#{size}-[a-z0-9]{8}\.png)
        expect(cache_control).to eq "max-age=3600, public"
      end
    end

    describe "GET /apple-touch-icon-#{size}-precomposed.png" do
      it "redirects to the specific icon asset" do
        get "/apple-touch-icon-#{size}-precomposed.png"

        expect(response).to have_http_status(:temporary_redirect)
        expect(location).to match %r(https://petition\.parliament\.uk/assets/os-social/apple/apple-touch-icon-#{size}-[a-z0-9]{8}\.png)
        expect(cache_control).to eq "max-age=3600, public"
      end
    end
  end

  %w[57x57 60x60 72x72 76x76 114x114 144x144].each do |size|
    describe "GET /apple-touch-icon-#{size}.png" do
      it "redirects to the generic icon asset" do
        get "/apple-touch-icon-#{size}.png"

        expect(response).to have_http_status(:temporary_redirect)
        expect(location).to eq "https://petition.parliament.uk/assets/os-social/apple/apple-touch-icon-5820e4ad.png"
        expect(cache_control).to eq "max-age=3600, public"
      end
    end

    describe "GET /apple-touch-icon-#{size}-precomposed.png" do
      it "redirects to the generic icon asset" do
        get "/apple-touch-icon-#{size}-precomposed.png"

        expect(response).to have_http_status(:temporary_redirect)
        expect(location).to eq "https://petition.parliament.uk/assets/os-social/apple/apple-touch-icon-5820e4ad.png"
        expect(cache_control).to eq "max-age=3600, public"
      end
    end
  end
end
