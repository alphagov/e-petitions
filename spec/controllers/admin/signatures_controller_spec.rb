require 'rails_helper'

RSpec.describe Admin::SignaturesController, type: :controller, admin: true do
  let!(:petition) { FactoryGirl.create(:open_petition) }
  let!(:signature) { FactoryGirl.create(:validated_signature, petition: petition, email: "user@example.com") }

  context "not logged in" do
    describe "GET /admin/signatures" do
      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end

    describe "DELETE /admin/signatures/:id" do
      it "redirects to the login page" do
        delete :destroy, id: signature.id
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    let(:user) { FactoryGirl.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "GET /admin/signatures" do
      it "redirects to the edit profile page" do
        get :index
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end

    describe "DELETE /admin/signatures/:id" do
      it "redirects to edit profile page" do
        delete :destroy, id: signature.id
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end
  end

  context "logged in as moderator user" do
    let(:user) { FactoryGirl.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /admin/signatures" do
      let(:results) { double(:results, paginate: []) }

      it "sets the search_type" do
        get :index
        expect(assigns(:search_type)).to eq "signature"
      end

      context "query is not an email address or ip address" do
        let(:query) { "Joe Bloggs" }

        it "searches signatures by name" do
          expect(Signature).to receive(:for_name).with(query).and_return results
          get :index, q: query
        end

        it "passes on pagination params" do
          allow(Signature).to receive(:for_name).and_return(results)
          expect(results).to receive(:paginate).with hash_including(page: '3')
          get :index, q: query, page: '3'
        end
      end

      context "by email address" do
        let(:query) { "joe.bloggs@unboxed.com" }

        it "searches signatures by email" do
          expect(Signature).to receive(:for_email).with(query).and_return results
          get :index, q: query
        end

        it "passes on pagination params" do
          allow(Signature).to receive(:for_email).and_return(results)
          expect(results).to receive(:paginate).with hash_including(page: '3')
          get :index, q: query, page: '3'
        end
      end

      context "by IP address" do
        let(:query) { "192.168.1.1" }

        it "searches signatures by ip" do
          expect(Signature).to receive(:for_ip).with(query).and_return results
          get :index, q: query
        end

        it "passes on pagination params" do
          allow(Signature).to receive(:for_ip).and_return(results)
          expect(results).to receive(:paginate).with hash_including(page: '3')
          get :index, q: query, page: '3'
        end
      end
    end

    describe "POST /admin/signatures/:id/validate" do
      before do
        expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
      end

      context "when the signature is validated" do
        before do
          expect(signature).to receive(:validate!).and_return(true)
          post :validate, id: signature.id, q: "user@example.com"
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
          post :validate, id: signature.id, q: "user@example.com"
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
      before do
        expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
      end

      context "when the signature is validated" do
        before do
          expect(signature).to receive(:invalidate!).and_return(true)
          post :invalidate, id: signature.id, q: "user@example.com"
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
          post :invalidate, id: signature.id, q: "user@example.com"
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
      before do
        expect(Signature).to receive(:find).with(signature.id.to_s).and_return(signature)
      end

      context "when the signature is destroyed" do
        before do
          expect(signature).to receive(:destroy).and_return(true)
          delete :destroy, id: signature.id, q: "user@example.com"
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
          delete :destroy, id: signature.id, q: "user@example.com"
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
