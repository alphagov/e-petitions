require 'rails_helper'

RSpec.describe SponsorsController, type: :controller do
  let(:signature_collection_disabled?) { false }

  before do
    constituency = FactoryBot.create(:constituency, :london_and_westminster)
    allow(Constituency).to receive(:find_by_postcode).with("SW1A1AA").and_return(constituency)

    allow(Site).to receive(:signature_collection_disabled?).and_return(signature_collection_disabled?)
  end

  describe "GET /petitions/:petition_id/sponsors/new" do
    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :new, params: { petition_id: 1, token: 'token' }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "redirects to the petition gathering support page" do
        get :new, params: { petition_id: petition.id, token: 'token' }
        expect(response).to redirect_to("/petitions/#{petition.id}/gathering-support")
      end
    end

    context "when the creator's signature has not been validated" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:creator) { petition.creator }

      it "validates the creator's signature" do
        expect {
          get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
        }.to change {
          creator.reload.validated?
        }.from(false).to(true)
      end
    end

    %w[dormant hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    %w[pending validated sponsored flagged].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "assigns the @signature instance variable with a new signature" do
          expect(assigns[:signature]).not_to be_persisted
        end

        it "is on stage 'uk_citizenship'" do
          expect(assigns[:signature].stage).to eq "uk_citizenship";
        end

        it "sets the signature's location_code to 'GB'" do
          expect(assigns[:signature].location_code).to eq("GB")
        end

        it "renders the sponsors/new template" do
          expect(response).to render_template("sponsors/new")
        end

        context "and has one remaining sponsor slot" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

          it "doesn't redirect to the petition moderation info page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end

        context "and has reached the maximum number of sponsors" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

          it "redirects to the petition moderation info page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end

        context "and signature collection is paused" do
          let(:signature_collection_disabled?) { true }

          it "sets the flash :notice message" do
            expect(flash[:notice]).to eq("Sorry, you can’t sign petitions at the moment")
          end

          it "redirects to the petition page" do
            expect(response).to redirect_to("/petitions/#{petition.to_param}")
          end
        end
      end
    end
  end

  describe "POST /petitions/:petition_id/sponsors/new" do
    let(:params) do
      {
        name: "Ted Berry",
        email: "ted@example.com",
        uk_citizenship: "1",
        postcode: "SW1A 1AA",
        location_code: "GB"
      }
    end

    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :create, params: { petition_id: 1, token: 'token', stage: 'replay_email', signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "redirects to the petition gathering support page" do
        post :create, params: { petition_id: petition.id, token: 'token', stage: 'replay_email', signature: params }
        expect(response).to redirect_to("/petitions/#{petition.id}/gathering-support")
      end
    end

    %w[dormant hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            post :create, params: { petition_id: petition.id, token: petition.sponsor_token, stage: 'replay_email', signature: params }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          post :create, params: { petition_id: petition.id, token: petition.sponsor_token, stage: 'replay_email', signature: params }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    %w[pending validated sponsored flagged].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        context "and the signature is not a duplicate" do
          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, stage: 'replay_email', signature: params }
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "sets the signature's params" do
            expect(assigns[:signature].name).to eq("Ted Berry")
            expect(assigns[:signature].email).to eq("ted@example.com")
            expect(assigns[:signature].uk_citizenship).to eq("1")
            expect(assigns[:signature].postcode).to eq("SW1A1AA")
            expect(assigns[:signature].location_code).to eq("GB")
          end

          it "records the IP address on the signature" do
            expect(assigns[:signature].ip_address).to eq("0.0.0.0")
          end

          it "sends a confirmation email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Sign to support: “#{petition.action}”")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end

          context "and the params are invalid" do
            let(:params) do
              {
                name: "Ted Berry",
                email: "",
                uk_citizenship: "1",
                postcode: "SW1A 1AA",
                location_code: "GB"
              }
            end

            it "renders the sponsors/new template" do
              expect(response).to render_template("sponsors/new")
            end
          end
        end

        context "and the signature is a pending duplicate" do
          let!(:signature) { FactoryBot.create(:pending_signature, params.merge(petition: petition)) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, stage: 'replay_email', signature: params }
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "re-sends the confirmation email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Sign to support: “#{petition.action}”")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end
        end

        context "and the signature is a pending duplicate alias" do
          let!(:signature) { FactoryBot.create(:pending_signature, params.merge(petition: petition)) }

          before do
            allow(Site).to receive(:disable_plus_address_check?).and_return(true)

            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, stage: 'replay_email', signature: params.merge(email: "ted+petitions@example.com") }
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "re-sends the confirmation email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Sign to support: “#{petition.action}”")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end
        end

        context "and the signature is a validated duplicate" do
          let!(:signature) { FactoryBot.create(:validated_signature, params.merge(petition: petition)) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, stage: "replay_email", signature: params }
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "sends a duplicate signature email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Duplicate signature of petition")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end
        end

        context "and the signature is a validated duplicate alias" do
          let!(:signature) { FactoryBot.create(:validated_signature, params.merge(petition: petition)) }

          before do
            allow(Site).to receive(:disable_plus_address_check?).and_return(true)

            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, stage: "replay_email", signature: params.merge(email: "ted+petitions@example.com") }
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "sends a duplicate signature email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Duplicate signature of petition")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end
        end

        context "and has one remaining sponsor slot" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, stage: "replay_email", signature: params }
            }
          end

          it "doesn't redirect to the petition moderation info page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end

        context "and has reached the maximum number of sponsors" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          it "redirects to the petition moderation info page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end

        context "and signature collection is paused" do
          let(:signature_collection_disabled?) { true }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, stage: 'replay_email', signature: params }
            }
          end

          it "sets the flash :notice message" do
            expect(flash[:notice]).to eq("Sorry, you can’t sign petitions at the moment")
          end

          it "redirects to the petition page" do
            expect(response).to redirect_to("/petitions/#{petition.to_param}")
          end
        end
      end
    end
  end

  describe "GET /petitions/:petition_id/signatures/thank-you" do
    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :thank_you, params: { petition_id: 1, token: 'token' }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "redirects to the petition gathering support page" do
        get :thank_you, params: { petition_id: petition.id, token: 'token' }
        expect(response).to redirect_to("/petitions/#{petition.id}/gathering-support")
      end
    end

    %w[dormant hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :thank_you, params: { petition_id: petition.id, token: petition.sponsor_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          get :thank_you, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "doesn't redirect to the petition page" do
          expect(response).not_to redirect_to("/petitions/#{petition.id}")
        end

        it "renders the signatures/thank_you template" do
          expect(response).to render_template("signatures/thank_you")
        end
      end
    end

    %w[pending validated sponsored flagged].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

        before do
          get :thank_you, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "renders the signatures/thank_you template" do
          expect(response).to render_template("signatures/thank_you")
        end

        context "and has one remaining sponsor slot" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

          it "doesn't redirect to the petition moderation info page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
          end

          it "renders the signatures/thank_you template" do
            expect(response).to render_template("signatures/thank_you")
          end
        end

        context "and has reached the maximum number of sponsors" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

          it "doesn't redirect to the petition moderation info page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
          end

          it "renders the signatures/thank_you template" do
            expect(response).to render_template("signatures/thank_you")
          end
        end

        context "and signature collection is paused" do
          let(:signature_collection_disabled?) { true }

          it "sets the flash :notice message" do
            expect(flash[:notice]).to eq("Sorry, you can’t sign petitions at the moment")
          end

          it "redirects to the petition page" do
            expect(response).to redirect_to("/petitions/#{petition.to_param}")
          end
        end
      end
    end
  end

  describe "GET /sponsors/:id/verify" do
    let(:parsed_cookie) { JSON.parse(cookies.encrypted[:signed_tokens]) }

    context "when the signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: 1, token: "token" }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

      it "redirects to the petition gathering support page" do
        get :verify, params: { id: signature.id, token: "token" }
        expect(response).to redirect_to("/petitions/#{petition.id}/gathering-support")
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition, sponsor: true) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }.not_to raise_error
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition, sponsor: true) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }.not_to raise_error
      end
    end

    %w[dormant hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :verify, params: { id: signature.id, token: signature.perishable_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

        before do
          get :verify, params: { id: signature.id, token: signature.perishable_token }
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
    end

    context "when the petition is pending" do
      let(:petition) { FactoryBot.create(:pending_petition, creator_attributes: { email: "bob@example.com" }) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true, name: "Alice") }
      let(:other_petition) { FactoryBot.create(:open_petition) }
      let(:other_signature) { FactoryBot.create(:validated_signature, petition: other_petition) }

      before do
        cookies.encrypted[:signed_tokens] = {
          other_signature.id.to_s => other_signature.signed_token
        }.to_json

        perform_enqueued_jobs {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }
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

      it "validates the creator" do
        expect(petition.creator.reload).to be_validated
      end

      it "changes the petition state to validated" do
        expect(petition.reload).to be_validated
      end

      it "records the constituency id on the signature" do
        expect(assigns[:signature].constituency_id).to eq("3415")
      end

      it "records the ip address on the signature" do
        expect(assigns[:signature].validated_ip).to eq("0.0.0.0")
      end

      it "deletes old signed tokens" do
        expect(parsed_cookie).not_to have_key(other_signature.id.to_s)
      end

      it "saves the signed token in the cookie" do
        expect(parsed_cookie).to eq({ signature.id.to_s => signature.signed_token })
      end

      it "sends email notification to the petition creator" do
        expect(last_email_sent).to deliver_to("bob@example.com")
        expect(last_email_sent).to have_subject("Someone supported: “#{petition.action}”")
      end

      it "redirects to the signed signature page" do
        expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
      end

      context "and the signature has already been validated" do
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

        it "doesn't set the flash :notice message" do
          expect(flash[:notice]).to be_nil
        end
      end

      context "and signature collection is paused" do
        let(:signature_collection_disabled?) { true }

        it "sets the flash :notice message" do
          expect(flash[:notice]).to eq("Sorry, you can’t sign petitions at the moment")
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.to_param}")
        end
      end
    end

    context "when the petition is validated" do
      let(:petition) { FactoryBot.create(:validated_petition, creator_attributes: { email: "bob@example.com" }) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true, name: "Alice") }
      let(:other_petition) { FactoryBot.create(:open_petition) }
      let(:other_signature) { FactoryBot.create(:validated_signature, petition: other_petition) }

      before do
        cookies.encrypted[:signed_tokens] = {
          other_signature.id.to_s => other_signature.signed_token
        }.to_json

        perform_enqueued_jobs {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }
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
        expect(parsed_cookie).not_to have_key(other_signature.id.to_s)
      end

      it "saves the signed token in the cookie" do
        expect(parsed_cookie).to eq({ signature.id.to_s => signature.signed_token })
      end

      it "sends email notification to the petition creator" do
        expect(last_email_sent).to deliver_to("bob@example.com")
        expect(last_email_sent).to have_subject("Someone supported: “#{petition.action}”")
      end

      it "redirects to the signed signature page" do
        expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
      end

      context "and the signature has already been validated" do
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

        it "doesn't set the flash :notice message" do
          expect(flash[:notice]).to be_nil
        end

        it "doesn't send another email" do
          expect(deliveries).to be_empty
        end
      end

      context "and the signature has been validated more than 15 minutes ago" do
        let(:signature) { FactoryBot.create(:validated_signature, validated_at: 30.minutes.ago, petition: petition, sponsor: true) }

        it "redirects to the new sponsor page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/new?token=#{petition.sponsor_token}")
        end
      end

      context "and is at the threshold for moderation" do
        let(:petition) { FactoryBot.create(:validated_petition, sponsor_count: Site.minimum_number_of_sponsors - 1, sponsors_signed: true, creator_attributes: { email: "bob@example.com" }) }

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

        it "saves the signed token in the cookie" do
          expect(parsed_cookie).to eq({ signature.id.to_s => signature.signed_token })
        end

        it "sends email notification to the petition creator" do
          expect(last_email_sent).to deliver_to("bob@example.com")
          expect(last_email_sent).to have_subject("Your petition has five supporters: “#{petition.action}”")
        end

        it "redirects to the signed signature page" do
          expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
        end
      end

      context "and has one remaining sponsor slot" do
        let(:petition) { FactoryBot.create(:validated_petition, sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true, creator_attributes: { email: "bob@example.com" }) }

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

        it "saves the signed token in the cookie" do
          expect(parsed_cookie).to eq({ signature.id.to_s => signature.signed_token })
        end

        it "sends email notification to the petition creator" do
          expect(last_email_sent).to deliver_to("bob@example.com")
          expect(last_email_sent).to have_subject("Your petition has five supporters: “#{petition.action}”")
        end

        it "redirects to the signed signature page" do
          expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
        end
      end

      context "and has reached the maximum number of sponsors" do
        let(:petition) { FactoryBot.create(:validated_petition, sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

        it "redirects to the petition moderation info page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
        end
      end

      context "and signature collection is paused" do
        let(:signature_collection_disabled?) { true }

        it "sets the flash :notice message" do
          expect(flash[:notice]).to eq("Sorry, you can’t sign petitions at the moment")
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.to_param}")
        end
      end
    end

    context "when the petition is sponsored" do
      let(:petition) { FactoryBot.create(:sponsored_petition, creator_attributes: { email: "bob@example.com" }) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true, name: "Alice") }
      let(:other_petition) { FactoryBot.create(:open_petition) }
      let(:other_signature) { FactoryBot.create(:validated_signature, petition: other_petition) }

      before do
        cookies.encrypted[:signed_tokens] = {
          other_signature.id.to_s => other_signature.signed_token
        }.to_json

        perform_enqueued_jobs {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }
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
        expect(parsed_cookie).not_to have_key(other_signature.id.to_s)
      end

      it "saves the signed token in the cookie" do
        expect(parsed_cookie).to eq({ signature.id.to_s => signature.signed_token })
      end

      it "doesn't send an email notification to the petition creator" do
        expect(deliveries).to be_empty
      end

      it "redirects to the signed signature page" do
        expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
      end

      context "and the signature has already been validated" do
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

        it "doesn't set the flash :notice message" do
          expect(flash[:notice]).to be_nil
        end
      end

      context "and has one remaining sponsor slot" do
        let(:petition) { FactoryBot.create(:sponsored_petition, sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true, creator_attributes: { email: "bob@example.com" }) }

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

        it "saves the signed token in the cookie" do
          expect(parsed_cookie).to eq({ signature.id.to_s => signature.signed_token })
        end

        it "doesn't send an email notification to the petition creator" do
          expect(deliveries).to be_empty
        end

        it "redirects to the signed signature page" do
          expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
        end
      end

      context "and has reached the maximum number of sponsors" do
        let(:petition) { FactoryBot.create(:sponsored_petition, sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

        it "redirects to the petition moderation info page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
        end
      end

      context "and signature collection is paused" do
        let(:signature_collection_disabled?) { true }

        it "sets the flash :notice message" do
          expect(flash[:notice]).to eq("Sorry, you can’t sign petitions at the moment")
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.to_param}")
        end
      end
    end

    context "when the petition is flagged" do
      let(:petition) { FactoryBot.create(:flagged_petition, creator_attributes: { email: "bob@example.com" }) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true, name: "Alice") }
      let(:other_petition) { FactoryBot.create(:open_petition) }
      let(:other_signature) { FactoryBot.create(:validated_signature, petition: other_petition) }

      before do
        cookies.encrypted[:signed_tokens] = {
          other_signature.id.to_s => other_signature.signed_token
        }.to_json

        perform_enqueued_jobs {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }
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
        expect(parsed_cookie).not_to have_key(other_signature.id.to_s)
      end

      it "saves the signed token in the cookie" do
        expect(parsed_cookie).to eq({ signature.id.to_s => signature.signed_token })
      end

      it "doesn't send an email notification to the petition creator" do
        expect(deliveries).to be_empty
      end

      it "redirects to the signed signature page" do
        expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
      end

      context "and the signature has already been validated" do
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

        it "doesn't set the flash :notice message" do
          expect(flash[:notice]).to be_nil
        end
      end

      context "and has one remaining sponsor slot" do
        let(:petition) { FactoryBot.create(:flagged_petition, sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true, creator_attributes: { email: "bob@example.com" }) }

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

        it "saves the signed token in the cookie" do
          expect(parsed_cookie).to eq({ signature.id.to_s => signature.signed_token })
        end

        it "doesn't send an email notification to the petition creator" do
          expect(deliveries).to be_empty
        end

        it "redirects to the signed signature page" do
          expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored")
        end
      end

      context "and has reached the maximum number of sponsors" do
        let(:petition) { FactoryBot.create(:flagged_petition, sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

        it "redirects to the petition moderation info page" do
          expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
        end
      end

      context "and signature collection is paused" do
        let(:signature_collection_disabled?) { true }

        it "sets the flash :notice message" do
          expect(flash[:notice]).to eq("Sorry, you can’t sign petitions at the moment")
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.to_param}")
        end
      end
    end
  end

  describe "GET /sponsors/:id/sponsored" do
    let(:parsed_cookie) { JSON.parse(cookies.encrypted[:signed_tokens]) }

    context "when the signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: 1 }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signed token is missing" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

      it "redirects to the petition gathering support page" do
        get :signed, params: { id: signature.id }
        expect(response).to redirect_to("/petitions/#{petition.id}/gathering-support")
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition, sponsor: true) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: signature.id }
        }.not_to raise_error
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition, sponsor: true) }

      it "doesn't raise an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: signature.id }
        }.not_to raise_error
      end
    end

    %w[dormant hidden stopped].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition, sponsor: true) }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :signed, params: { id: signature.id }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition, sponsor: true) }

        before do
          cookies.encrypted[:signed_tokens] = { signature.id.to_s => signature.signed_token }.to_json
          get :signed, params: { id: signature.id }
        end

        it "assigns the @signature instance variable" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "doesn't redirect to the petition page" do
          expect(response).not_to redirect_to("/petitions/#{petition.id}")
        end

        it "renders the sponsors/signed template" do
          expect(response).to render_template("sponsors/signed")
        end
      end
    end

    %w[pending validated sponsored flagged].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition, sponsor: true) }

        context "and the signature has been validated" do
          before do
            cookies.encrypted[:signed_tokens] = { signature.id.to_s => signature.signed_token }.to_json
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

          it "renders the sponsors/signed template" do
            expect(response).to render_template("sponsors/signed")
          end

          it "deletes the signed token from the cookie" do
            expect(parsed_cookie).to be_empty
          end

          context "and the signature has already seen the confirmation page" do
            let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

            it "assigns the @signature instance variable" do
              expect(assigns[:signature]).to eq(signature)
            end

            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "renders the sponsors/signed template" do
              expect(response).to render_template("sponsors/signed")
            end
          end

          context "and has one remaining sponsor slot" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 2, sponsors_signed: true) }

            it "assigns the @signature instance variable" do
              expect(assigns[:signature]).to eq(signature)
            end

            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "marks the signature has having seen the confirmation page" do
              expect(assigns[:signature].seen_signed_confirmation_page).to eq(true)
            end

            it "renders the sponsors/signed template" do
              expect(response).to render_template("sponsors/signed")
            end
          end

          context "and has reached the maximum number of sponsors" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

            it "assigns the @signature instance variable" do
              expect(assigns[:signature]).to eq(signature)
            end

            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "marks the signature has having seen the confirmation page" do
              expect(assigns[:signature].seen_signed_confirmation_page).to eq(true)
            end

            it "renders the sponsors/signed template" do
              expect(response).to render_template("sponsors/signed")
            end
          end

          context "and signature collection is paused" do
            let(:signature_collection_disabled?) { true }

            it "sets the flash :notice message" do
              expect(flash[:notice]).to eq("Sorry, you can’t sign petitions at the moment")
            end

            it "redirects to the petition page" do
              expect(response).to redirect_to("/petitions/#{petition.to_param}")
            end
          end
        end

        context "and the signature has not been validated" do
          let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

          before do
            get :signed, params: { id: signature.id }
          end

          it "redirects to the correct petition page" do
            if petition.collecting_sponsors?
              expect(response).to redirect_to("/petitions/#{petition.id}/gathering-support")
            else
              expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
            end
          end

          context "and signature collection is paused" do
            let(:signature_collection_disabled?) { true }

            it "sets the flash :notice message" do
              expect(flash[:notice]).to eq("Sorry, you can’t sign petitions at the moment")
            end

            it "redirects to the petition page" do
              expect(response).to redirect_to("/petitions/#{petition.to_param}")
            end
          end
        end
      end
    end
  end
end
