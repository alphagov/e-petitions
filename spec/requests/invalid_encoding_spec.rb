require 'rails_helper'

RSpec.describe "invalid encoding", type: :request do
  describe "when sponsoring a petition" do
    let(:petition) { FactoryBot.create(:validated_petition, sponsor_token: "foobar") }

    it "raises an ActiveRecord::RecordNotFound exception" do
      expect {
        get "/petitions/#{petition.id}/sponsors/new?token=foobar%91"
      }.to raise_error(ActiveRecord::RecordNotFound, 'Unable to find Petition with sponsor token: "foobar�"')
    end
  end

  describe "when validating a sponsor signature" do
    let(:petition) { FactoryBot.create(:validated_petition) }
    let(:signature) { FactoryBot.create(:pending_signature, sponsor: true, perishable_token: "foobar", petition: petition)}

    it "raises an ActiveRecord::RecordNotFound exception" do
      expect {
        get "/sponsors/#{signature.id}/verify?token=foobar%91"
      }.to raise_error(ActiveRecord::RecordNotFound, 'Unable to find Signature with token: "foobar�"')
    end
  end

  describe "when validating a signature" do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:signature) { FactoryBot.create(:pending_signature, perishable_token: "foobar", petition: petition)}

    it "raises an ActiveRecord::RecordNotFound exception" do
      expect {
        get "/signatures/#{signature.id}/verify?token=foobar%91"
      }.to raise_error(ActiveRecord::RecordNotFound, 'Unable to find Signature with token: "foobar�"')
    end
  end

  describe "when unsubscribing a signature" do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:signature) { FactoryBot.create(:pending_signature, unsubscribe_token: "foobar", petition: petition)}

    it "raises an ActiveRecord::RecordNotFound exception" do
      expect {
        get "/signatures/#{signature.id}/unsubscribe?token=foobar%91"
      }.to raise_error(ActiveRecord::RecordNotFound, 'Unable to find Signature with unsubscribe token: "foobar�"')
    end
  end

  describe "when unsubscribing an archived signature" do
    let(:petition) { FactoryBot.create(:archived_petition) }
    let(:signature) { FactoryBot.create(:archived_signature, unsubscribe_token: "foobar", petition: petition)}

    it "raises an ActiveRecord::RecordNotFound exception" do
      expect {
        get "/archived/signatures/#{signature.id}/unsubscribe?token=foobar%91"
      }.to raise_error(ActiveRecord::RecordNotFound, 'Unable to find Signature with unsubscribe token: "foobar�"')
    end
  end
end
