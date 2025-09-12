require 'rails_helper'

RSpec.describe "invalid ids", type: :request, show_exceptions: true, csrf: false do
  describe "GET /archived/petitions/:id" do
    it "returns a 400 Bad Request" do
      get "/archived/petitions/not-a-number"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /archived/signatures/:id/unsubscribe" do
    it "returns a 400 Bad Request" do
      get "/archived/signatures/not-a-number/unsubscribe"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /petitions/:id" do
    it "returns a 400 Bad Request" do
      get "/petitions/not-a-number"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /petitions/:id/count.json" do
    it "returns a 400 Bad Request" do
      get "/petitions/not-a-number/count.json"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /petitions/:id/gathering-support" do
    it "returns a 400 Bad Request" do
      get "/petitions/not-a-number/gathering-support"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /petitions/:id/moderation-info" do
    it "returns a 400 Bad Request" do
      get "/petitions/not-a-number/moderation-info"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /petitions/:petition_id/sponsors/new" do
    it "returns a 400 Bad Request" do
      get "/petitions/not-a-number/sponsors/new"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /petitions/:petition_id/sponsors/new" do
    it "returns a 400 Bad Request" do
      post "/petitions/not-a-number/sponsors/new"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /petitions/:petition_id/sponsors/thank-you" do
    it "returns a 400 Bad Request" do
      get "/petitions/not-a-number/sponsors/thank-you"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /sponsors/:id/verify" do
    it "returns a 400 Bad Request" do
      get "/sponsors/not-a-number/verify"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /sponsors/:id/sponsored" do
    it "returns a 400 Bad Request" do
      get "/sponsors/not-a-number/sponsored"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /petitions/:petition_id/signatures/new" do
    it "returns a 400 Bad Request" do
      get "/petitions/not-a-number/signatures/new"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /petitions/:petition_id/signatures/new" do
    it "returns a 400 Bad Request" do
      post "/petitions/not-a-number/signatures/new"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /petitions/:petition_id/signatures/thank-you" do
    it "returns a 400 Bad Request" do
      get "/petitions/not-a-number/signatures/thank-you"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /signatures/:id/verify" do
    it "returns a 400 Bad Request" do
      get "/signatures/not-a-number/verify"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /signatures/:id/signed" do
    it "returns a 400 Bad Request" do
      get "/signatures/not-a-number/signed"
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /signatures/:id/unsubscribe" do
    it "returns a 400 Bad Request" do
      get "/signatures/not-a-number/unsubscribe"
      expect(response).to have_http_status(:bad_request)
    end
  end
end
