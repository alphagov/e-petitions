require 'rails_helper'

RSpec.describe "legacy tokens", type: :request do
  let(:petition) { FactoryGirl.create(:open_petition) }

  before do
    stub_any_api_request
  end

  describe "when verifying the signature" do
    let(:signature) { FactoryGirl.create(:pending_signature, petition: petition) }

    before do
      get "/signatures/#{signature.id}/verify/#{signature.perishable_token}"
    end

    it "verifies the signature" do
      expect(signature.reload).to be_validated
    end
  end

  describe "when viewing the signed page" do
    let(:signature) { FactoryGirl.create(:validated_signature, :just_signed, petition: petition) }

    before do
      get "/signatures/#{signature.id}/signed/#{signature.perishable_token}"
    end

    it "shows the signed page" do
      expect(response.body).to match(/We've added your signature to the petition/)
    end
  end

  describe "when unsubscribing" do
    let(:signature) { FactoryGirl.create(:validated_signature, petition: petition) }

    before do
      get "/signatures/#{signature.id}/unsubscribe/#{signature.unsubscribe_token}"
    end

    it "unsubscribes the signer" do
      expect(signature.reload).to be_unsubscribed
    end
  end
end
