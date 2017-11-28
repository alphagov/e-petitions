require 'rails_helper'

RSpec.describe Archived::SignaturesController, type: :controller do
  describe '#unsubscribe' do
    let(:signature) { double(:signature, id: 1, unsubscribe_token: "token") }
    let(:petition) { double(:petition) }

    before do
      expect(Archived::Signature).to receive(:find).with("1").and_return(signature)
      expect(signature).to receive(:petition).and_return(petition)
      allow(signature).to receive(:fraudulent?).and_return(false)
      allow(signature).to receive(:invalidated?).and_return(false)
    end

    context "when the signature is validated" do
      before do
        expect(signature).to receive(:unsubscribe!).with("token")
      end

      it "renders the action template" do
        get :unsubscribe, params: { id: "1", token: "token" }
        expect(response).to render_template(:unsubscribe)
      end
    end

    context "when the signature is fraudulent" do
      before do
        expect(signature).to receive(:fraudulent?).and_return(true)
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          get :unsubscribe, params: { id: "1", token: "token" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is invalidated" do
      before do
        expect(signature).to receive(:invalidated?).and_return(true)
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          get :unsubscribe, params: { id: "1", token: "token" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
