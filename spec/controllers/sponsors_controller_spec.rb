require 'rails_helper'

RSpec.describe SponsorsController, type: :controller do
  context 'GET show' do
    let(:petition) { FactoryGirl.create(:petition) }

    it 'fetches the requested petition' do
      get :show, params: { petition_id: petition, token: petition.sponsor_token }
      expect(assigns[:petition]).to eq petition
    end

    # TODO: check for invalid petition states?
    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        get :show, params: { petition_id: petition_param, token: petition.sponsor_token }
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        get :show, params: { petition_id: petition, token: petition_2.sponsor_token }
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'renders the form' do
      get :show, params: { petition_id: petition, token: petition.sponsor_token }
      expect(response).to render_template :show
    end

    it 'builds a new sponsor for the petition identified by the token' do
      get :show, params: { petition_id: petition, token: petition.sponsor_token }
      expect(assigns[:sponsor]).to be_new_record
      expect(assigns[:sponsor].petition).to eq petition
    end

    it 'builds a signature for the sponsor' do
      get :show, params: { petition_id: petition, token: petition.sponsor_token }
      expect(assigns[:stage_manager].signature).to be_present
      expect(assigns[:stage_manager].signature.petition).to eq petition
    end

    it 'redirects to petition page when the petition is closed' do
      closed_petition = FactoryGirl.create(:closed_petition)
      get :show, params: { petition_id: closed_petition, token: closed_petition.sponsor_token }
      redirect_url = "https://petition.parliament.uk/petitions/#{closed_petition.id}"
      expect(response).to redirect_to redirect_url
    end

    it 'redirects to petition page when the petition is rejected' do
      rejected_petition = FactoryGirl.create(:rejected_petition)
      get :show, params: { petition_id: rejected_petition, token: rejected_petition.sponsor_token }
      redirect_url = "https://petition.parliament.uk/petitions/#{rejected_petition.id}"
      expect(response).to redirect_to redirect_url
    end

    it 'redirects to petition view page if the petition is already published' do
      published_petition = FactoryGirl.create(:open_petition)
      get :show, params: { petition_id: published_petition, token: published_petition.sponsor_token }
      redirect_url = "https://petition.parliament.uk/petitions/#{published_petition.id}"
      expect(response).to redirect_to redirect_url
    end

    it 'redirects to 404 if the petition is hidden' do
      hidden_petition = FactoryGirl.create(:hidden_petition)
      expect {
        get :show, params: { petition_id: hidden_petition, token: hidden_petition.sponsor_token }
      }.to raise_error ActiveRecord::RecordNotFound
    end

    context 'creator signature is pending' do
      let(:petition) { FactoryGirl.create(:pending_petition) }
      let(:signature) { petition.creator_signature }

      it 'validates the creator signature' do
        expect {
          get :show, params: { petition_id: petition.id, token: petition.sponsor_token }
        }.to change{ signature.reload.validated? }.from(false).to(true)
      end
    end

    context 'petition has reached maximum amount of sponsors' do
      it 'redirects to petition moderation info page when petition is in sponsored state' do
        sponsored_petition = FactoryGirl.create(:sponsored_petition, sponsor_count: Site.maximum_number_of_sponsors)
        get :show, params: { petition_id: sponsored_petition, token: sponsored_petition.sponsor_token }
        redirect_url = "https://petition.parliament.uk/petitions/#{sponsored_petition.id}/moderation-info"
        expect(response).to redirect_to redirect_url
      end

      it 'redirects to petition moderation info page when petition is in validated state' do
        validated_petition = FactoryGirl.create(:validated_petition, sponsor_count: Site.maximum_number_of_sponsors)
        get :show, params: { petition_id: validated_petition, token: validated_petition.sponsor_token }
        redirect_url = "https://petition.parliament.uk/petitions/#{validated_petition.id}/moderation-info"
        expect(response).to redirect_to redirect_url
      end

      it 'redirects to petition moderation info page when petition is in pending state' do
        pending_petition = FactoryGirl.create(:pending_petition, sponsor_count: Site.maximum_number_of_sponsors)
        get :show, params: { petition_id: pending_petition, token: pending_petition.sponsor_token }
        redirect_url = "https://petition.parliament.uk/petitions/#{pending_petition.id}/moderation-info"
        expect(response).to redirect_to redirect_url
      end
    end
  end

  context 'PATCH update' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:signature_params) {
      {
        name: 'S. Ponsor',
        email: 's.ponsor@example.com',
        postcode: 'SP11NR',
        location_code: 'GB',
        uk_citizenship: '1',
        notify_by_email: '0'
      }
    }

    let(:constituency) do
      FactoryGirl.create(
        :constituency, external_id: '54321', name: 'Sponsor-upon-petition'
      )
    end

    def do_patch(options = {})
      params = {
        petition_id: petition,
        token: petition.sponsor_token,
        signature: signature_params,
        stage: 'replay-email',
        move: 'next'
      }.merge(options)

      allow(Constituency).to receive(:find_by_postcode).with("SP11NR").and_return(constituency)

      perform_enqueued_jobs do
        patch :update, params: params
      end
    end

    let(:signature) { petition.signatures.for_email('s.ponsor@example.com').first }

    context 'managing the "move" parameter' do
      it 'defaults to "next" if it is not present' do
        do_patch :move => nil
        expect(controller.params['move']).to eq 'next'
      end

      it 'defaults to "next" if it is present but blank' do
        do_patch :move => ''
        expect(controller.params['move']).to eq 'next'
      end

      it 'overrides it to "next" if it is present but not "next" or "back"' do
        do_patch :move => 'blah'
        expect(controller.params['move']).to eq 'next'
      end

      it 'overrides it to "next" if "move:next" is present' do
        do_patch :move => 'blah', :'move:next' => 'Onwards!'
        expect(controller.params['move']).to eq 'next'
      end

      it 'overrides it to "back" if "move:back" is present' do
        do_patch :move => 'blah', :'move:back' => 'Backwards!'
        expect(controller.params['move']).to eq 'back'
      end

      it 'overrides it to "next" if both "move:next" and "move:back" are present' do
        do_patch :move => 'blah',  :'move:next' => 'Onwards!', :'move:back' => 'Backwards!'
        expect(controller.params['move']).to eq 'next'
      end
    end

    it '404s if the requested petition does not exist' do
      petition.destroy
      expect {
        do_patch
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        do_patch token: petition_2.sponsor_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    context 'with valid signature params' do
      it 'creates a sponsor signature for the petition with the supplied params' do
        do_patch
        expect(signature).to be_present
        expect(signature).to be_sponsor
        expect(signature.name).to eq signature_params[:name]
        expect(signature.postcode).to eq signature_params[:postcode]
        expect(signature.location_code).to eq signature_params[:location_code]
        expect(signature.notify_by_email).to eq true
        expect(petition.sponsors.for(signature)).to be_present
      end

      it 'creates the signature in the pending state' do
        do_patch
        expect(signature).to be_pending
        expect(signature.perishable_token).not_to be_nil
      end

      it "sets the constituency_id on the creator signature, based on the postcode" do
        do_patch
        expect(signature.constituency_id).to eq("54321")
      end

      it 'redirects to the thank you page' do
        do_patch
        redirect_url = "https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{petition.sponsor_token}/thank-you"
        expect(response).to redirect_to redirect_url
      end

      it "allows overriding of the email via params" do
        signature_params[:email] = 'not-the-sponsors-email-address@example.com'
        do_patch
        expect(signature).to be_nil
        created_signature = petition.signatures.for_email('not-the-sponsors-email-address@example.com').first
        expect(created_signature).to be_present
      end

      it "overrides the petition of the signature, no matter what has been passed in" do
        signature_params[:petition_id] = (petition.id + 1000).to_s
        do_patch
        expect(signature.petition).to eq petition
      end

      it "ignores attempts to set the state of signature" do
        signature_params[:state] = 'not-a-state'
        do_patch
        expect(signature).to be_pending
      end

      it "emails the sponsor" do
        do_patch
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to eq(['s.ponsor@example.com'])
      end
    end

    context 'with invalid signature params' do
      before { signature_params[:name] = '' }

      it 'does not persist the signature' do
        do_patch
        expect(signature).not_to be_present
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
        do_patch signature: signature_params.merge(:location_code => '')
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

    context "when a race condition occurs" do
      let(:exception) { ActiveRecord::RecordNotUnique.new("PG::UniqueViolation") }

      before do
        FactoryGirl.create(:sponsor, :validated, petition: petition)
        allow_any_instance_of(Signature).to receive(:save).and_raise(exception)
      end

      it "redirects to the thank you page" do
        do_patch
        expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{petition.sponsor_token}/thank-you")
      end
    end
  end

  context 'GET thank-you' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
    let(:signature) { sponsor.create_signature!(FactoryGirl.attributes_for(:pending_signature)) }

    before { signature.present? }

    it 'fetches the requested petition' do
      get :thank_you, params: { petition_id: petition, token: petition.sponsor_token }
      expect(assigns[:petition]).to eq petition
    end

    # TODO: check for invalid petition states?
    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        get :thank_you, params: { petition_id: petition_param, token: petition.sponsor_token }
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        get :thank_you, params: { petition_id: petition, token: petition_2.sponsor_token }
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'renders the view' do
      get :thank_you, params: { petition_id: petition, token: petition.sponsor_token }
      expect(response).to render_template :thank_you
    end

    context "when the petition has the maximum number of sponsors" do
      let(:petition) { FactoryGirl.create(:petition, sponsor_count: 19) }

      it "does not redirect to the moderation page" do
        get :thank_you, params: { petition_id: petition, token: petition.sponsor_token }
        expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
      end
    end
  end

  context 'GET sponsored' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
    let(:signature) { sponsor.create_signature!(FactoryGirl.attributes_for(:validated_signature)) }

    before { signature.present? }

    it 'fetches the requested petition' do
      get :sponsored, params: { petition_id: petition, token: petition.sponsor_token }
      expect(assigns[:petition]).to eq petition
    end

    # TODO: check for invalid petition states?
    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        get :sponsored, params: { petition_id: petition_param, token: petition.sponsor_token }
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        get :sponsored, params: { petition_id: petition, token: petition_2.sponsor_token }
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'renders the view' do
      get :sponsored, params: { petition_id: petition, token: petition.sponsor_token }
      expect(response).to render_template :sponsored
    end

    context "when the petition has the maximum number of sponsors" do
      let(:petition) { FactoryGirl.create(:petition, sponsor_count: 19) }

      it "does not redirect to the moderation page" do
        get :sponsored, params: { petition_id: petition, token: petition.sponsor_token }
        expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
      end
    end
  end
end
