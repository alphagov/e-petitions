require 'rails_helper'

RSpec.describe Admin::SignaturesController, type: :controller, admin: true do
  let!(:petition) { FactoryBot.create(:open_petition) }
  let!(:signature) { FactoryBot.create(:validated_signature, petition: petition, email: "user@example.com") }

  context "not logged in" do
    describe "GET /admin/signatures" do
      it "redirects to the login page" do
        get :index, params: { q: "Alice" }
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end

    describe "DELETE /admin/signatures/:id" do
      it "redirects to the login page" do
        delete :destroy, params: { id: signature.id }
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end
  end

  context "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    let(:token) { SecureRandom.base64(32) }
    let(:verifier) { ActiveSupport::MessageVerifier.new(token, serializer: JSON) }
    let(:signature_ids) { verifier.generate([signature.id]) }

    before do
      login_as(user)
      session[:_bulk_verification_token] = token
    end

    describe "GET /admin/signatures" do
      before { get :index, params: { q: "Alice" } }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :index template" do
        expect(response).to render_template("admin/signatures/index")
      end
    end

    describe "POST /admin/signatures/:id/validate" do
      context "when the signature is validated" do
        before do
          expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
          expect(signature).to receive(:validate!).and_return(true)
          post :validate, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signature validated successfully")
        end
      end

      context "when the signature is not validated" do
        let(:exception) { ActiveRecord::StatementInvalid.new("Invalid SQL") }

        before do
          expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
          expect(signature).to receive(:validate!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)
          post :validate, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signature could not be validated - please contact support")
        end
      end
    end

    describe "POST /admin/signatures/:id/invalidate" do
      context "when the signature is validated" do
        before do
          expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
          expect(signature).to receive(:invalidate!).and_return(true)
          post :invalidate, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signature invalidated successfully")
        end
      end

      context "when the signature is not validated" do
        let(:exception) { ActiveRecord::StatementInvalid.new("Invalid SQL") }

        before do
          expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
          expect(signature).to receive(:invalidate!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)
          post :invalidate, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signature could not be invalidated - please contact support")
        end
      end
    end

    describe "POST /admin/signatures/:id/subscribe" do
      before do
        signature.update!(notify_by_email: false)
      end

      context "and the update succeeds" do
        it "redirects to the search page" do
          post :subscribe, params: { id: signature.id, q: "user@example.com" }
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash notice message" do
          post :subscribe, params: { id: signature.id, q: "user@example.com" }
          expect(flash[:notice]).to eq("Signature subscribed successfully")
        end

        it "changes the notify_by_email attribute" do
          expect {
            post :subscribe, params: { id: signature.id, q: "user@example.com" }
          }.to change {
            signature.reload.notify_by_email
          }.from(false).to(true)
        end
      end

      context "and the update fails" do
        before do
          expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
          expect(signature).to receive(:update).with(notify_by_email: true).and_return(false)
        end

        it "redirects to the search page" do
          post :subscribe, params: { id: signature.id, q: "user@example.com" }
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash alert message" do
          post :subscribe, params: { id: signature.id, q: "user@example.com" }
          expect(flash[:alert]).to eq("Signature could not be subscribed - please contact support")
        end
      end
    end

    describe "POST /admin/signatures/:id/unsubscribe" do
      before do
        signature.update!(notify_by_email: true)
      end

      context "and the update succeeds" do
        it "redirects to the search page" do
          post :unsubscribe, params: { id: signature.id, q: "user@example.com" }
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash notice message" do
          post :unsubscribe, params: { id: signature.id, q: "user@example.com" }
          expect(flash[:notice]).to eq("Signature unsubscribed successfully")
        end

        it "changes the notify_by_email attribute" do
          expect {
            post :unsubscribe, params: { id: signature.id, q: "user@example.com" }
          }.to change {
            signature.reload.notify_by_email
          }.from(true).to(false)
        end
      end

      context "and the update fails" do
        before do
          expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
          expect(signature).to receive(:update).with(notify_by_email: false).and_return(false)
        end

        it "redirects to the search page" do
          post :unsubscribe, params: { id: signature.id, q: "user@example.com" }
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash alert message" do
          post :unsubscribe, params: { id: signature.id, q: "user@example.com" }
          expect(flash[:alert]).to eq("Signature could not be unsubscribed - please contact support")
        end
      end
    end

    describe "DELETE /admin/signatures/:id" do
      context "when the signature is destroyed" do
        before do
          expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
          expect(signature).to receive(:destroy).and_return(true)
          delete :destroy, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signature removed successfully")
        end
      end

      context "when the signature is not destroyed" do
        before do
          expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
          expect(signature).to receive(:destroy).and_return(false)
          delete :destroy, params: { id: signature.id, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signature could not be removed - please contact support")
        end
      end
    end

    describe "POST /admin/signatures/validate" do
      context "when the signature is validated" do
        before do
          expect(Signature).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:validate!).and_return(true)
          post :bulk_validate, params: { selected_ids: signature.id, all_ids: signature_ids, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signatures validated successfully")
        end
      end

      context "when the signature is not validated" do
        let(:exception) { ActiveRecord::StatementInvalid.new("Invalid SQL") }

        before do
          expect(Signature).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:validate!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)
          post :bulk_validate, params: { selected_ids: signature.id, all_ids: signature_ids, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signatures could not be validated - please contact support")
        end
      end

      context "when the signature ids hmac is missing" do
        before do
          expect(Signature).not_to receive(:find)
        end

        it "returns a 400 Bad Request" do
          expect {
            delete :bulk_validate, params: { selected_ids: signature.id, all_ids: "", q: "user@example.com" }
          }.to raise_error(BulkVerification::InvalidBulkRequest, /Invalid bulk request for \[\d+\]/)
        end
      end

      context "when the selected_ids param contains an invalid id" do
        before do
          expect(Signature).not_to receive(:find)
        end

        it "returns a 400 Bad Request" do
          expect {
            delete :bulk_validate, params: { selected_ids: "1,2", all_ids: signature_ids, q: "user@example.com" }
          }.to raise_error(BulkVerification::InvalidBulkRequest, /Invalid bulk request - \d+ not present in \[\d+\]/)
        end
      end
    end

    describe "POST /admin/signatures/invalidate" do
      context "when the signature is invalidated" do
        before do
          expect(Signature).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:invalidate!).and_return(true)
          post :bulk_invalidate, params: { selected_ids: signature.id, all_ids: signature_ids, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signatures invalidated successfully")
        end
      end

      context "when the signature is not invalidated" do
        let(:exception) { ActiveRecord::StatementInvalid.new("Invalid SQL") }

        before do
          expect(Signature).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:invalidate!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)
          post :bulk_invalidate, params: { selected_ids: signature.id, all_ids: signature_ids, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signatures could not be invalidated - please contact support")
        end
      end

      context "when the signature ids hmac is missing" do
        before do
          expect(Signature).not_to receive(:find)
        end

        it "returns a 400 Bad Request" do
          expect {
            delete :bulk_invalidate, params: { selected_ids: signature.id, all_ids: "", q: "user@example.com" }
          }.to raise_error(BulkVerification::InvalidBulkRequest, /Invalid bulk request for \[\d+\]/)
        end
      end

      context "when the selected_ids param contains an invalid id" do
        before do
          expect(Signature).not_to receive(:find)
        end

        it "returns a 400 Bad Request" do
          expect {
            delete :bulk_invalidate, params: { selected_ids: "1,2", all_ids: signature_ids, q: "user@example.com" }
          }.to raise_error(BulkVerification::InvalidBulkRequest, /Invalid bulk request - \d+ not present in \[\d+\]/)
        end
      end
    end

    describe "POST /admin/signatures/subscribe" do
      context "when the signature is subcribed" do
        before do
          expect(Signature).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:update!).with(notify_by_email: true).and_return(true)
          post :bulk_subscribe, params: { selected_ids: signature.id, all_ids: signature_ids, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signatures subscribed successfully")
        end
      end

      context "when the signature is not subscribed" do
        let(:exception) { ActiveRecord::StatementInvalid.new("Invalid SQL") }

        before do
          expect(Signature).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:update!).with(notify_by_email: true).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)
          post :bulk_subscribe, params: { selected_ids: signature.id, all_ids: signature_ids, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signatures could not be subscribed - please contact support")
        end
      end

      context "when the signature ids hmac is missing" do
        before do
          expect(Signature).not_to receive(:find)
        end

        it "returns a 400 Bad Request" do
          expect {
            delete :bulk_subscribe, params: { selected_ids: signature.id, all_ids: "", q: "user@example.com" }
          }.to raise_error(BulkVerification::InvalidBulkRequest, /Invalid bulk request for \[\d+\]/)
        end
      end

      context "when the selected_ids param contains an invalid id" do
        before do
          expect(Signature).not_to receive(:find)
        end

        it "returns a 400 Bad Request" do
          expect {
            delete :bulk_subscribe, params: { selected_ids: "1,2", all_ids: signature_ids, q: "user@example.com" }
          }.to raise_error(BulkVerification::InvalidBulkRequest, /Invalid bulk request - \d+ not present in \[\d+\]/)
        end
      end
    end

    describe "POST /admin/signatures/unsubscribe" do
      context "when the signature is unsubcribed" do
        before do
          expect(Signature).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:update!).with(notify_by_email: false).and_return(true)
          post :bulk_unsubscribe, params: { selected_ids: signature.id, all_ids: signature_ids, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signatures unsubscribed successfully")
        end
      end

      context "when the signature is not unsubscribed" do
        let(:exception) { ActiveRecord::StatementInvalid.new("Invalid SQL") }

        before do
          expect(Signature).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:update!).with(notify_by_email: false).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)
          post :bulk_unsubscribe, params: { selected_ids: signature.id, all_ids: signature_ids, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signatures could not be unsubscribed - please contact support")
        end
      end

      context "when the signature ids hmac is missing" do
        before do
          expect(Signature).not_to receive(:find)
        end

        it "returns a 400 Bad Request" do
          expect {
            delete :bulk_unsubscribe, params: { selected_ids: signature.id, all_ids: "", q: "user@example.com" }
          }.to raise_error(BulkVerification::InvalidBulkRequest, /Invalid bulk request for \[\d+\]/)
        end
      end

      context "when the selected_ids param contains an invalid id" do
        before do
          expect(Signature).not_to receive(:find)
        end

        it "returns a 400 Bad Request" do
          expect {
            delete :bulk_unsubscribe, params: { selected_ids: "1,2", all_ids: signature_ids, q: "user@example.com" }
          }.to raise_error(BulkVerification::InvalidBulkRequest, /Invalid bulk request - \d+ not present in \[\d+\]/)
        end
      end
    end

    describe "DELETE /admin/signatures" do
      context "when the signature is destroyed" do
        before do
          expect(Signature).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:destroy!).and_return(true)
          delete :bulk_destroy, params: { selected_ids: signature.id, all_ids: signature_ids, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Signatures removed successfully")
        end
      end

      context "when the signature is not destroyed" do
        let(:exception) { ActiveRecord::RecordNotDestroyed.new("Cannot delete the creator signature") }

        before do
          expect(Signature).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:destroy!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)
          delete :bulk_destroy, params: { selected_ids: signature.id, all_ids: signature_ids, q: "user@example.com" }
        end

        it "redirects to the search page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/signatures?q=user%40example.com")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Signatures could not be removed - please contact support")
        end
      end

      context "when the signature ids hmac is missing" do
        before do
          expect(Signature).not_to receive(:find)
        end

        it "returns a 400 Bad Request" do
          expect {
            delete :bulk_destroy, params: { selected_ids: signature.id, all_ids: "", q: "user@example.com" }
          }.to raise_error(BulkVerification::InvalidBulkRequest, /Invalid bulk request for \[\d+\]/)
        end
      end

      context "when the selected_ids param contains an invalid id" do
        before do
          expect(Signature).not_to receive(:find)
        end

        it "returns a 400 Bad Request" do
          expect {
            delete :bulk_destroy, params: { selected_ids: "1,2", all_ids: signature_ids, q: "user@example.com" }
          }.to raise_error(BulkVerification::InvalidBulkRequest, /Invalid bulk request - \d+ not present in \[\d+\]/)
        end
      end
    end
  end
end
