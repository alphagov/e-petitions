require 'rails_helper'

RSpec.describe "missing a 'token'", type: :request, show_exceptions: true do
  let(:petition) { FactoryBot.create(:open_petition) }

  describe "when verifying the signature" do
    let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

    before do
      get "/signatures/#{signature.id}/verify"
    end

    it "returns 404 Not Found" do
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "when viewing the signed page" do
    let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

    before do
      get "/signatures/#{signature.id}/signed"
    end

    it "returns 404 Not Found" do
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "when unsubscribing" do
    let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }

    before do
      get "/signatures/#{signature.id}/unsubscribe"
    end

    it "returns 404 Not Found" do
      expect(response).to have_http_status(:not_found)
    end
  end
end
