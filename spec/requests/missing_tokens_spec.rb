require 'rails_helper'

RSpec.describe "missing a 'token'", type: :request, show_exceptions: true do
  let(:petition) { FactoryBot.create(:open_petition) }

  context "when verifying the signature" do
    let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

    before do
      get "/signatures/#{signature.id}/verify"
    end

    it "returns 404 Not Found" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when viewing the signed page" do
    let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

    before do
      get "/signatures/#{signature.id}/signed"
    end

    it "redirects to the petition page" do
      expect(response).to redirect_to("/petitions/#{petition.id}")
    end
  end

  context "when unsubscribing" do
    let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }

    before do
      get "/signatures/#{signature.id}/unsubscribe"
    end

    it "returns 404 Not Found" do
      expect(response).to have_http_status(:not_found)
    end
  end
end
