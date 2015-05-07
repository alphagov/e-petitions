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
        redirect_path = thank_you_petition_sponsor_path(petition, token: sponsor.perishable_token, secure: true)
        expect(response).to redirect_to redirect_path
      end
    end

    context 'when the sponsor has not signed the petition yet' do
      it 'renders the form' do
        get :show, petition_id: petition, token: sponsor.perishable_token
        expect(response).to render_template :show
      end

      it 'builds a signature for the sponsor' do
        get :show, petition_id: petition, token: sponsor.perishable_token
        expect(assigns[:signature]).to be_present
        expect(assigns[:signature].petition).to eq sponsor.petition
        expect(assigns[:signature].email).to eq sponsor.email
      end
    end
  end

  context 'PATCH update' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
    let(:signature_params) {
      {
        name: 'S. Ponsor',
        address: '1 Sponsor St.',
        town: 'Sponsorsville',
        postcode: 'SP1 1NR',
        country: 'United Kingdom',
        uk_citizenship: '1',
        notify_by_email: '0',
        terms_and_conditions: '1'
      }
    }

    def do_patch
      patch :update, petition_id: petition,
                     token: sponsor.perishable_token,
                     signature: signature_params
      sponsor.reload
    end

    context 'when the sponsor has already signed the petition' do
      before { sponsor.create_signature!(FactoryGirl.attributes_for(:validated_signature, name: 'P. Sonsor')) }

      it 'redirects to the thank-you page if the sponsor has already signed the petition' do
        do_patch
        redirect_path = thank_you_petition_sponsor_path(petition, token: sponsor.perishable_token, secure: true)
        expect(response).to redirect_to redirect_path
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
          expect(sponsor.signature.notify_by_email).to eq false
        end

        it 'creates the signature in the validated state' do
          do_patch
          expect(sponsor.signature.state).to eq Signature::VALIDATED_STATE
          expect(sponsor.signature.perishable_token).to be_nil
        end

        it 'creates a signature for the sponsor using the email and petition from the sponsor' do
          do_patch
          expect(sponsor.signature.email).to eq sponsor.email
          expect(sponsor.signature.petition).to eq sponsor.petition
        end

        it 'redirects to the thank you page' do
          do_patch
          redirect_path = thank_you_petition_sponsor_path(petition, token: sponsor.perishable_token, secure: true)
          expect(response).to redirect_to redirect_path
        end
      end

      context 'with invalid signature params' do
        before { signature_params[:terms_and_conditions] = '0' }

        it 'does not persist the signature' do
          do_patch
          expect(sponsor.signature).not_to be_present
          expect(assigns[:signature]).not_to be_persisted
        end

        it 'renders the form again' do
          do_patch
          expect(response).to render_template :show
        end
      end
    end
  end

  context 'GET thank-you' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
    let(:signature) { sponsor.create_signature!(FactoryGirl.attributes_for(:validated_signature)) }

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

    it 'renders the view if the sponsor has signed the petition' do
      get :thank_you, petition_id: petition, token: sponsor.perishable_token
      expect(response).to render_template :thank_you
    end

    it 'redirects to show if the sponsor has not signed the petition' do
      signature.destroy
      get :thank_you, petition_id: petition, token: sponsor.perishable_token
      expect(response).to redirect_to petition_sponsor_path(petition, token: sponsor.perishable_token, secure: true)
    end
  end
end
