require 'rails_helper'

RSpec.describe Admin::SignaturesController, type: :controller, admin: true do
  let!(:petition) { FactoryGirl.create(:open_petition) }
  let!(:signature) { FactoryGirl.create(:validated_signature, petition: petition, email: "user@example.com") }

  context "not logged in" do
    describe "DELETE /admin/signatures/:id" do
      it "redirects to the login page" do
        delete :destroy, params: { id: signature.id }
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    let(:user) { FactoryGirl.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "DELETE /admin/signatures/:id" do
      it "redirects to edit profile page" do
        delete :destroy, params: { id: signature.id }
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end
  end

  context "logged in as moderator user" do
    let(:user) { FactoryGirl.create(:moderator_user) }
    before { login_as(user) }
    before { expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature) }

    describe "POST /admin/signatures/:id/validate" do
      context "when the signature is validated" do
        before do
          expect(signature).to receive(:validate!).and_return(true)
          post :validate, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/search?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signature validated successfully")
        end
      end

      context "when the signature is not validated" do
        let(:exception) { ActiveRecord::StatementInvalid.new("Invalid SQL") }

        before do
          expect(signature).to receive(:validate!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)
          post :validate, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/search?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signature could not be validated - please contact support")
        end
      end
    end

    describe "POST /admin/signatures/:id/invalidate" do
      context "when the signature is validated" do
        before do
          expect(signature).to receive(:invalidate!).and_return(true)
          post :invalidate, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/search?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signature invalidated successfully")
        end
      end

      context "when the signature is not validated" do
        let(:exception) { ActiveRecord::StatementInvalid.new("Invalid SQL") }

        before do
          expect(signature).to receive(:invalidate!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)
          post :invalidate, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/search?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signature could not be invalidated - please contact support")
        end
      end
    end

    describe "DELETE /admin/signatures/:id" do
      context "when the signature is destroyed" do
        before do
          expect(signature).to receive(:destroy).and_return(true)
          delete :destroy, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/search?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signature removed successfully")
        end
      end

      context "when the signature is not destroyed" do
        before do
          expect(signature).to receive(:destroy).and_return(false)
          delete :destroy, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/search?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signature could not be removed - please contact support")
        end
      end
    end
  end
end
