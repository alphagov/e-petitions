require 'rails_helper'

RSpec.describe SignaturesController, type: :controller do
  before do
    constituency = FactoryBot.create(:constituency, :london_and_westminster)
    allow(Constituency).to receive(:find_by_postcode).with("SW1A1AA").and_return(constituency)
  end

  describe "GET /petitions/:petition_id/signatures/new" do
    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :new, params: { petition_id: 1 }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    %w[pending validated sponsored flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :new, params: { petition_id: petition.id }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          get :new, params: { petition_id: petition.id }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    context "when the petition is open" do
      let(:petition) { FactoryBot.create(:open_petition) }

      before do
        get :new, params: { petition_id: petition.id }
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "assigns the @signature instance variable with a new signature" do
        expect(assigns[:signature]).not_to be_persisted
      end

      it "sets the signature's location_code to 'GB'" do
        expect(assigns[:signature].location_code).to eq("GB")
      end

      it "renders the signatures/new template" do
        expect(response).to render_template("signatures/new")
      end
    end
  end

  describe "POST /petitions/:petition_id/signatures/new" do
    let(:params) do
      {
        name: "Ted Berry",
        email: "ted@example.com",
        postcode: "SW1A 1AA",
        location_code: "GB"
      }
    end

    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :confirm, params: { petition_id: 1, signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    %w[pending validated sponsored flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            post :confirm, params: { petition_id: petition.id, signature: params }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          post :confirm, params: { petition_id: petition.id, signature: params }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    context "when the petition is open" do
      let(:petition) { FactoryBot.create(:open_petition) }

      before do
        post :confirm, params: { petition_id: petition.id, signature: params }
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "assigns the @signature instance variable with a new signature" do
        expect(assigns[:signature]).not_to be_persisted
      end

      it "sets the signature's params" do
        expect(assigns[:signature].name).to eq("Ted Berry")
        expect(assigns[:signature].email).to eq("ted@example.com")
        expect(assigns[:signature].postcode).to eq("SW1A1AA")
        expect(assigns[:signature].location_code).to eq("GB")
      end

      it "records the IP address on the signature" do
        expect(assigns[:signature].ip_address).to eq("0.0.0.0")
      end

      it "renders the signatures/confirm template" do
        expect(response).to render_template("signatures/confirm")
      end

      context "and the params are invalid" do
        let(:params) do
          {
            name: "Ted Berry",
            email: "",
            postcode: "12345",
            location_code: "GB"
          }
        end

        it "renders the signatures/new template" do
          expect(response).to render_template("signatures/new")
        end
      end
    end
  end

  describe "POST /petitions/:petition_id/signatures" do
    let(:params) do
      {
        name: "Ted Berry",
        email: "ted@example.com",
        postcode: "SW1A 1AA",
        location_code: "GB"
      }
    end

    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :create, params: { petition_id: 1, signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    %w[pending validated sponsored flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            post :create, params: { petition_id: petition.id, signature: params }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          post :create, params: { petition_id: petition.id, signature: params }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    context "when the petition is open" do
      let(:petition) { FactoryBot.create(:open_petition) }

      context "and the signature is not a duplicate" do
        before do
          perform_enqueued_jobs {
            post :create, params: { petition_id: petition.id, signature: params }
          }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "assigns the @signature instance variable with a saved signature" do
          expect(assigns[:signature]).to be_persisted
        end

        it "sets the signature's params" do
          expect(assigns[:signature].name).to eq("Ted Berry")
          expect(assigns[:signature].email).to eq("ted@example.com")
          expect(assigns[:signature].postcode).to eq("SW1A1AA")
          expect(assigns[:signature].location_code).to eq("GB")
        end

        it "records the IP address on the signature" do
          expect(assigns[:signature].ip_address).to eq("0.0.0.0")
        end

        it "sends a confirmation email" do
          expect(last_email_sent).to deliver_to("ted@example.com")
          expect(last_email_sent).to have_subject("Please confirm your email address")
        end

        it "redirects to the thank you page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/signatures/thank-you")
        end

        context "and the params are invalid" do
          let(:params) do
            {
              name: "Ted Berry",
              email: "",
              postcode: "SW1A 1AA",
              location_code: "GB"
            }
          end

          it "renders the signatures/new template" do
            expect(response).to render_template("signatures/new")
          end
        end
      end

      context "and the signature is a pending duplicate" do
        let!(:signature) { FactoryBot.create(:pending_signature, params.merge(petition: petition)) }

        before do
          perform_enqueued_jobs {
            post :create, params: { petition_id: petition.id, signature: params }
          }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "assigns the @signature instance variable to the original signature" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "re-sends the confirmation email" do
          expect(last_email_sent).to deliver_to("ted@example.com")
          expect(last_email_sent).to have_subject("Please confirm your email address")
        end

        it "redirects to the thank you page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/signatures/thank-you")
        end
      end

      context "and the signature is a pending duplicate alias" do
        let!(:signature) { FactoryBot.create(:pending_signature, params.merge(petition: petition)) }

        before do
          allow(Site).to receive(:disable_plus_address_check?).and_return(true)

          perform_enqueued_jobs {
            post :create, params: { petition_id: petition.id, signature: params.merge(email: "ted+petitions@example.com") }
          }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "assigns the @signature instance variable to the original signature" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "re-sends the confirmation email" do
          expect(last_email_sent).to deliver_to("ted@example.com")
          expect(last_email_sent).to have_subject("Please confirm your email address")
        end

        it "redirects to the thank you page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/signatures/thank-you")
        end
      end

      context "and the signature is a validated duplicate" do
        let!(:signature) { FactoryBot.create(:validated_signature, params.merge(petition: petition)) }

        before do
          perform_enqueued_jobs {
            post :create, params: { petition_id: petition.id, signature: params }
          }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "assigns the @signature instance variable to the original signature" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "sends a duplicate signature email" do
          expect(last_email_sent).to deliver_to("ted@example.com")
          expect(last_email_sent).to have_subject("Duplicate signature of petition")
        end

        it "redirects to the thank you page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/signatures/thank-you")
        end
      end

      context "and the signature is a validated duplicate alias" do
        let!(:signature) { FactoryBot.create(:validated_signature, params.merge(petition: petition)) }

        before do
          allow(Site).to receive(:disable_plus_address_check?).and_return(true)

          perform_enqueued_jobs {
            post :create, params: { petition_id: petition.id, signature: params.merge(email: "ted+petitions@example.com") }
          }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "assigns the @signature instance variable to the original signature" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "sends a duplicate signature email" do
          expect(last_email_sent).to deliver_to("ted@example.com")
          expect(last_email_sent).to have_subject("Duplicate signature of petition")
        end

        it "redirects to the thank you page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/signatures/thank-you")
        end
      end
    end
  end

  describe "GET /petitions/:petition_id/signatures/thank-you" do
    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :thank_you, params: { petition_id: 1 }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    %w[pending validated sponsored flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :thank_you, params: { petition_id: petition.id }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when the petition was rejected" do
      let(:petition) { FactoryBot.create(:rejected_petition) }

      before do
        get :thank_you, params: { petition_id: petition.id }
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "sets the flash :notice message" do
        expect(flash[:notice]).to eq("Sorry, you can't sign petitions that have been rejected")
      end

      it "redirects to the petition page" do
        expect(response).to redirect_to("/petitions/#{petition.id}")
      end
    end

    context "when the petition was closed more than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: 36.hours.ago) }
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }

      before do
        get :thank_you, params: { petition_id: petition.id }
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "sets the flash :notice message" do
        expect(flash[:notice]).to eq("Sorry, you can't sign petitions that have been closed")
      end

      it "redirects to the petition page" do
        expect(response).to redirect_to("/petitions/#{petition.id}")
      end
    end

    context "when the petition was closed less than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: 12.hours.ago) }
      let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

      before do
        get :thank_you, params: { petition_id: petition.id }
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "sets the flash :notice message" do
        expect(flash[:notice]).to eq("Sorry, you can't sign petitions that have been closed")
      end

      it "redirects to the petition page" do
        expect(response).to redirect_to("/petitions/#{petition.id}")
      end
    end

    context "when the petition is open" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

      before do
        get :thank_you, params: { petition_id: petition.id }
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "renders the signatures/thank_you template" do
        expect(response).to render_template("signatures/thank_you")
      end
    end
  end

  describe "GET /signatures/:id/verify" do
    context "when the signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: 1, token: "token" }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature token is invalid" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: "token" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }.not_to raise_error
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }.not_to raise_error
      end
    end

    %w[pending validated sponsored flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :verify, params: { id: signature.id, token: signature.perishable_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when the petition was rejected" do
      let(:petition) { FactoryBot.create(:rejected_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      before do
        get :verify, params: { id: signature.id, token: signature.perishable_token }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "sets the flash :notice message" do
        expect(flash[:notice]).to eq("Sorry, you can't sign petitions that have been rejected")
      end

      it "redirects to the petition page" do
        expect(response).to redirect_to("/petitions/#{petition.id}")
      end
    end

    context "when the petition was closed more than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: 36.hours.ago) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      before do
        get :verify, params: { id: signature.id, token: signature.perishable_token }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "sets the flash :notice message" do
        expect(flash[:notice]).to eq("Sorry, you can't sign petitions that have been closed")
      end

      it "redirects to the petition page" do
        expect(response).to redirect_to("/petitions/#{petition.id}")
      end
    end

    context "when the petition was closed less than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: 12.hours.ago) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      before do
        get :verify, params: { id: signature.id, token: signature.perishable_token }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "validates the signature" do
        expect(assigns[:signature]).to be_validated
      end

      it "records the constituency id on the signature" do
        expect(assigns[:signature].constituency_id).to eq("3415")
      end

      it "records the ip address on the signature" do
        expect(assigns[:signature].validated_ip).to eq("0.0.0.0")
      end

      it "saves the signed token in the session" do
        expect(session[:signed_tokens]).to eq({ signature.id.to_s => signature.signed_token })
      end

      it "redirects to the signed signature page" do
        expect(response).to redirect_to("/signatures/#{signature.id}/signed")
      end
    end

    context "when the petition is open" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }
      let(:other_petition) { FactoryBot.create(:open_petition) }
      let(:other_signature) { FactoryBot.create(:validated_signature, petition: other_petition) }

      before do
        session[:signed_tokens] = {
          other_signature.id.to_s => other_signature.signed_token
        }

        get :verify, params: { id: signature.id, token: signature.perishable_token }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "validates the signature" do
        expect(assigns[:signature]).to be_validated
      end

      it "records the constituency id on the signature" do
        expect(assigns[:signature].constituency_id).to eq("3415")
      end

      it "records the ip address on the signature" do
        expect(assigns[:signature].validated_ip).to eq("0.0.0.0")
      end

      it "deletes old signed tokens" do
        expect(session[:signed_tokens]).not_to have_key(other_signature.id.to_s)
      end

      it "saves the signed token in the session" do
        expect(session[:signed_tokens]).to eq({ signature.id.to_s => signature.signed_token })
      end

      it "redirects to the signed signature page" do
        expect(response).to redirect_to("/signatures/#{signature.id}/signed")
      end

      context "and the signature has already been validated" do
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }

        it "doesn't set the flash :notice message" do
          expect(flash[:notice]).to be_nil
        end
      end
    end
  end

  describe "GET /signatures/:id/signed" do
    context "when the signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: 1, token: "token" }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signed token is missing" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      it "redirects to the petition page" do
        get :signed, params: { id: signature.id }
        expect(response).to redirect_to("/petitions/#{petition.id}")
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: signature.id, token: signature.perishable_token }
        }.not_to raise_error
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: signature.id }
        }.not_to raise_error
      end
    end

    %w[pending validated sponsored flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :signed, params: { id: signature.id }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when the petition was rejected" do
      let(:petition) { FactoryBot.create(:rejected_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      before do
        get :signed, params: { id: signature.id }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "redirects to the petition page" do
        expect(response).to redirect_to("/petitions/#{petition.id}")
      end
    end

    context "when the petition was closed more than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: 36.hours.ago) }
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }

      before do
        get :signed, params: { id: signature.id }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "redirects to the petition page" do
        expect(response).to redirect_to("/petitions/#{petition.id}")
      end
    end

    context "when the petition was closed less than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: 12.hours.ago) }
      let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

      before do
        session[:signed_tokens] = { signature.id.to_s => signature.signed_token }
        get :signed, params: { id: signature.id }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "marks the signature has having seen the confirmation page" do
        expect(assigns[:signature].seen_signed_confirmation_page).to eq(true)
      end

      it "renders the signatures/signed template" do
        expect(response).to render_template("signatures/signed")
      end
    end

    context "when the petition is open" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

      context "when the signature has been validated" do
        before do
          session[:signed_tokens] = { signature.id.to_s => signature.signed_token }
          get :signed, params: { id: signature.id }
        end

        it "assigns the @signature instance variable" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "marks the signature has having seen the confirmation page" do
          expect(assigns[:signature].seen_signed_confirmation_page).to eq(true)
        end

        it "renders the signatures/signed template" do
          expect(response).to render_template("signatures/signed")
        end

        it "deletes the signed token from the session" do
          expect(session[:signed_tokens]).to be_empty
        end

        context "and the signature has already seen the confirmation page" do
          let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }

          it "doesn't redirect to the petition page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}")
          end
        end
      end

      context "when the signature has not been validated" do
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

        before do
          get :signed, params: { id: signature.id }
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end
  end

  describe "GET /signatures/:id/unsubscribe" do
    context "when the signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :unsubscribe, params: { id: 1, token: "token" }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature token is invalid" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :unsubscribe, params: { id: signature.id, token: "token" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :unsubscribe, params: { id: signature.id, token: signature.unsubscribe_token }
        }.not_to raise_error
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :unsubscribe, params: { id: signature.id, token: signature.unsubscribe_token }
        }.not_to raise_error
      end
    end

    %w[pending validated sponsored flagged hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :unsubscribe, params: { id: signature.id, token: signature.unsubscribe_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when the petition was rejected" do
      let(:petition) { FactoryBot.create(:rejected_petition) }
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }

      before do
        get :unsubscribe, params: { id: signature.id, token: signature.unsubscribe_token }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "unsubscribes from email updates" do
        expect(assigns[:signature].notify_by_email).to eq(false)
      end

      it "renders the signatures/unsubscribe template" do
        expect(response).to render_template("signatures/unsubscribe")
      end
    end

    context "when the petition was closed more than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: 36.hours.ago) }
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }

      before do
        get :unsubscribe, params: { id: signature.id, token: signature.unsubscribe_token }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "unsubscribes from email updates" do
        expect(assigns[:signature].notify_by_email).to eq(false)
      end

      it "renders the signatures/unsubscribe template" do
        expect(response).to render_template("signatures/unsubscribe")
      end
    end

    context "when the petition was closed less than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: 12.hours.ago) }
      let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

      before do
        get :unsubscribe, params: { id: signature.id, token: signature.unsubscribe_token }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "unsubscribes from email updates" do
        expect(assigns[:signature].notify_by_email).to eq(false)
      end

      it "renders the signatures/unsubscribe template" do
        expect(response).to render_template("signatures/unsubscribe")
      end
    end

    context "when the petition is open" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

      before do
        get :unsubscribe, params: { id: signature.id, token: signature.unsubscribe_token }
      end

      it "assigns the @signature instance variable" do
        expect(assigns[:signature]).to eq(signature)
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "unsubscribes from email updates" do
        expect(assigns[:signature].notify_by_email).to eq(false)
      end

      it "renders the signatures/unsubscribe template" do
        expect(response).to render_template("signatures/unsubscribe")
      end
    end
  end
end
