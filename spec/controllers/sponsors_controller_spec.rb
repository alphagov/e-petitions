require 'rails_helper'

describe SponsorsController do
  context 'GET show' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }

    it 'fetches the requested petition' do
      get :show, petition_id: petition, token: sponsor.perishable_token
      expect(assigns[:petition]).to eq petition
    end

    it 'fetches the requested sponsor by the token' do
      get :show, petition_id: petition, token: sponsor.perishable_token
      expect(assigns[:sponsor]).to eq sponsor
    end

    # TODO: check for invalid petition states?
    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        get :show, petition_id: petition_param, token: sponsor.perishable_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested sponsor token does not exist' do
      expect {
        get :show, petition_id: petition, token: 'not-a-real-sponsor-perishable-token'
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested sponsor token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        get :show, petition_id: petition_2, token: sponsor.perishable_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    context 'when the sponsor has already signed the petition' do
      before { sponsor.create_signature!(FactoryGirl.attributes_for(:validated_signature)) }

      it 'redirects to the thank-you page if the sponsor has already signed the petition' do
        get :show, petition_id: petition, token: sponsor.perishable_token
        redirect_url = "https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{sponsor.perishable_token}/thank-you"
        expect(response).to redirect_to redirect_url
      end
    end

    context 'when the sponsor has not signed the petition yet' do
      it 'renders the form' do
        get :show, petition_id: petition, token: sponsor.perishable_token
        expect(response).to render_template :show
      end

      it 'builds a signature for the sponsor' do
        get :show, petition_id: petition, token: sponsor.perishable_token
        expect(assigns[:stage_manager].signature).to be_present
        expect(assigns[:stage_manager].signature.petition).to eq sponsor.petition
        expect(assigns[:stage_manager].signature.email).to eq sponsor.email
      end
    end
  end

  context 'PATCH update' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
    let(:signature_params) {
      {
        name: 'S. Ponsor',
        email: sponsor.email,
        postcode: 'SP1 1NR',
        country: 'United Kingdom',
        uk_citizenship: '1',
        notify_by_email: '0'
      }
    }

    def do_patch(options = {})
      params = {
        petition_id: petition,
        token: sponsor.perishable_token,
        signature: signature_params,
        stage: 'replay-email',
        move: 'next'
      }.merge(options)
      patch :update, params
      sponsor.reload
    end

    context 'when the sponsor has already signed the petition' do
      before { sponsor.create_signature!(FactoryGirl.attributes_for(:validated_signature, name: 'P. Sonsor')) }

      it 'redirects to the thank-you page if the sponsor has already signed the petition' do
        do_patch
        redirect_url = "https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{sponsor.perishable_token}/thank-you"
        expect(response).to redirect_to redirect_url
      end

      it 'does not change the attributes of the existing signature' do
        do_patch
        expect(sponsor.signature.name).not_to eq signature_params[:name]
      end
    end

    context 'when the sponsor has not signed the petition yet' do
      context 'with valid signature params' do
        it 'creates a signature for the sponsor with the supplied params' do
          do_patch
          expect(sponsor.signature).to be_present
          expect(sponsor.signature.name).to eq signature_params[:name]
          expect(sponsor.signature.postcode).to eq signature_params[:postcode]
          expect(sponsor.signature.country).to eq signature_params[:country]
          expect(sponsor.signature.notify_by_email).to eq true
        end

        it 'creates the signature in the pending state' do
          do_patch
          expect(sponsor.signature).to be_pending
          expect(sponsor.signature.perishable_token).not_to be_nil
        end

        it 'creates a signature for the sponsor using the petition from the sponsor' do
          do_patch
          expect(sponsor.signature.petition).to eq sponsor.petition
        end

        it 'redirects to the thank you page' do
          do_patch
          redirect_url = "https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{sponsor.perishable_token}/thank-you"
          expect(response).to redirect_to redirect_url
        end

        it "allows overriding of the email via params" do
          signature_params[:email] = 'not-the-sponsors-email-address@example.com'
          do_patch
          expect(sponsor.signature.email).to eq 'not-the-sponsors-email-address@example.com'
        end

        it "overrides the petition of the signature, no matter what has been passed in" do
          signature_params[:petition_id] = (sponsor.petition.id + 1000).to_s
          do_patch
          expect(sponsor.signature.petition).to eq sponsor.petition
        end

        it "ignores attempts to set the state of signature" do
          signature_params[:state] = 'not-a-state'
          do_patch
          expect(sponsor.signature).to be_pending
        end

        it "emails the sponsor" do
          do_patch
          email = ActionMailer::Base.deliveries.last
          expect(email.to).to eq([sponsor.email])
        end
      end

      context 'with invalid signature params' do
        before { signature_params[:name] = '' }

        it 'does not persist the signature' do
          do_patch
          expect(sponsor.signature).not_to be_present
          expect(assigns[:stage_manager].signature).not_to be_persisted
        end

        it 'renders the form again' do
          do_patch
          expect(response).to render_template :show
        end

        it "has stage of 'signer' if there are errors on name, uk_citizenship, postcode or country" do
          do_patch signature: signature_params.merge(:name => '')
          expect(assigns[:stage_manager].stage).to eq 'signer'
          do_patch signature: signature_params.merge(:uk_citizenship => '')
          expect(assigns[:stage_manager].stage).to eq 'signer'
          do_patch signature: signature_params.merge(:postcode => '')
          expect(assigns[:stage_manager].stage).to eq 'signer'
          do_patch signature: signature_params.merge(:country => '')
          expect(assigns[:stage_manager].stage).to eq 'signer'
        end

        it "has stage of 'replay-email' if there are errors on email and we came from 'replay-email' stage" do
          new_signature_params = signature_params.merge(:email => 'foo@')
          do_patch stage: 'replay-email',
                   signature: new_signature_params
          expect(assigns[:stage_manager].stage).to eq 'replay-email'
        end

        it "has stage of 'creator' if there are errors on email and we came from 'signer' stage" do
          new_signature_params = signature_params.merge(:email => 'foo@')
          do_patch stage: 'signer',
                   signature: new_signature_params
          expect(assigns[:stage_manager].stage).to eq 'signer'
        end
      end
    end
  end

  context 'GET thank-you' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
    let(:signature) { sponsor.create_signature!(FactoryGirl.attributes_for(:pending_signature)) }

    before { signature.present? }

    it 'fetches the requested petition' do
      get :thank_you, petition_id: petition, token: sponsor.perishable_token
      expect(assigns[:petition]).to eq petition
    end

    it 'fetches the requested sponsor by the token' do
      get :thank_you, petition_id: petition, token: sponsor.perishable_token
      expect(assigns[:sponsor]).to eq sponsor
    end

    # TODO: check for invalid petition states?
    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        get :thank_you, petition_id: petition_param, token: sponsor.perishable_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested sponsor token does not exist' do
      expect {
        get :thank_you, petition_id: petition, token: 'not-a-real-sponsor-perishable-token'
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested sponsor token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        get :thank_you, petition_id: petition_2, token: sponsor.perishable_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'renders the view if the sponsor has signed the petition and not validated their signature' do
      get :thank_you, petition_id: petition, token: sponsor.perishable_token
      expect(response).to render_template :thank_you
    end

    it 'redirects to show if the sponsor has not signed the petition' do
      signature.destroy
      get :thank_you, petition_id: petition, token: sponsor.perishable_token
      expect(response).to redirect_to "https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{sponsor.perishable_token}"
    end

    it 'redirects to sponsored if the sponsor has signed the petition but already validated their signature' do
      signature.update_column(:state, Signature::VALIDATED_STATE)
      get :thank_you, petition_id: petition, token: sponsor.perishable_token
      expect(response).to redirect_to "https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{sponsor.perishable_token}/sponsored"
    end
  end

  context 'GET sponsored' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
    let(:signature) { sponsor.create_signature!(FactoryGirl.attributes_for(:validated_signature)) }

    before { signature.present? }

    it 'fetches the requested petition' do
      get :sponsored, petition_id: petition, token: sponsor.perishable_token
      expect(assigns[:petition]).to eq petition
    end

    it 'fetches the requested sponsor by the token' do
      get :sponsored, petition_id: petition, token: sponsor.perishable_token
      expect(assigns[:sponsor]).to eq sponsor
    end

    # TODO: check for invalid petition states?
    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        get :sponsored, petition_id: petition_param, token: sponsor.perishable_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested sponsor token does not exist' do
      expect {
        get :sponsored, petition_id: petition, token: 'not-a-real-sponsor-perishable-token'
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested sponsor token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        get :sponsored, petition_id: petition_2, token: sponsor.perishable_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'renders the view if the sponsor has signed the petition and validated their signature' do
      get :sponsored, petition_id: petition, token: sponsor.perishable_token
      expect(response).to render_template :sponsored
    end

    it 'redirects to show if the sponsor has not signed the petition yet' do
      signature.destroy
      get :sponsored, petition_id: petition, token: sponsor.perishable_token
      expect(response).to redirect_to "https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{sponsor.perishable_token}"
    end

    it 'redirects to thank-you if the sponsor has signed the petition, but not validated their signature yet' do
      signature.update_column(:state, Signature::PENDING_STATE)
      get :sponsored, petition_id: petition, token: sponsor.perishable_token
      expect(response).to redirect_to "https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{sponsor.perishable_token}/thank-you"
    end
  end
end
