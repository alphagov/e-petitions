require 'rails_helper'

describe SignaturesController do
  include ActiveJob::TestHelper

  describe "verify" do
    context "signature of user who is not the petition's creator" do
      let(:petition) { FactoryGirl.create(:petition) }
      let(:signature) { FactoryGirl.create(:pending_signature, :petition => petition) }
      let(:api_url) { ConstituencyApi::Client::URL }
      let(:fake_body) {
        "<Constituencies>
        <Constituency><Name>Cities of London and Westminster</Name></Constituency>
       </Constituencies>"
      }

      before do
        stub_request(:get, "#{ api_url }/SW1A1AA/").to_return(status: 200, body: fake_body)
      end

      it "should respond to /signatures/:id/verify/:token" do
        expect({:get => "/signatures/#{signature.id}/verify/#{signature.perishable_token}"}).
          to route_to({:controller => "signatures", :action => "verify", :id => signature.id.to_s, :token => signature.perishable_token})
        expect(verify_signature_path(signature, signature.perishable_token)).to eq("/signatures/#{signature.id}/verify/#{signature.perishable_token}")
      end

      it "should redirect to the petition signed page" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(assigns[:signature]).to eq(signature)
        expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{signature.petition_id}/signatures/#{signature.id}/signed")
      end

      it "should not set petition state to validated" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(petition.reload.state).to eq(Petition::PENDING_STATE)
      end

      it "should raise exception if id not found" do
        expect do
          get :verify, :id => signature.id + 1, :token => signature.perishable_token
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should raise exception if token not found" do
        expect do
          get :verify, :id => signature.id, :token => "#{signature.perishable_token}a"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'signature to be verified is a sponsor' do
      let(:petition) { FactoryGirl.create(:petition) }
      let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
      let(:signature) { sponsor.create_signature(FactoryGirl.attributes_for(:pending_signature, petition: petition)) }

      it "should redirect to the petition sponsored page" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(assigns[:signature]).to eq(signature)
        expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{petition.sponsor_token}/sponsored")
      end

      it "should set petition state to validated" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(petition.reload.state).to eq(Petition::VALIDATED_STATE)
      end

      it "should set state to validated" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(signature.reload.state).to eq(Signature::VALIDATED_STATE)
      end

      it "should set petition creator signature state to validated" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(petition.creator_signature.reload.state).to eq(Signature::VALIDATED_STATE)
      end

      it 'sends email notification to the petition creator' do
        perform_enqueued_jobs do
          get :verify, :id => signature.id, :token => signature.perishable_token
          email = ActionMailer::Base.deliveries.last
          expect(email.to).to eq([petition.creator_signature.email])
        end
      end

      it 'doesn\'t send email notification to the petition creator if the petition is already in moderation' do
        petition_in_moderation = FactoryGirl.create(:petition, state: 'sponsored')
        sponsor = FactoryGirl.create(:sponsor, petition: petition_in_moderation)
        signature = sponsor.create_signature(FactoryGirl.attributes_for(:pending_signature, petition: petition_in_moderation))
        assert_no_performed_jobs do
          get :verify, :id => signature.id, :token => signature.perishable_token
        end
      end

      it 'updates petition sponsored state' do
        allow(Signature).to receive(:find).with(signature.to_param).and_return signature
        allow(signature).to receive(:petition).and_return petition
        expect(petition).to receive(:update_state_after_new_validated_sponsor!)
        get :verify, :id => signature.id, :token => signature.perishable_token
      end

      it "should raise exception if id not found" do
        expect do
          get :verify, :id => signature.id + 1, :token => signature.perishable_token
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should raise exception if token not found" do
        expect do
          get :verify, :id => signature.id, :token => "#{signature.perishable_token}a"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "new" do
    let(:petition) { FactoryGirl.build(:petition) }

    before do
      allow(Petition).to receive_messages(:visible => Petition)
      allow(Petition).to receive(:find).with('1').and_return(petition)
    end

    it "assigns a new signature with the given petition" do
      get :new, :petition_id => 1
      expect(assigns(:stage_manager).signature.petition).to eq(petition)
    end

    it "sets the country to be UK" do
      get :new, :petition_id => 1
      expect(assigns(:stage_manager).signature.country).to eq 'United Kingdom'
    end

    it "finds the given petition" do
      get :new, :petition_id => 1
      expect(assigns(:petition)).to eq petition
    end

    it "raises if petition id is not supplied" do
      expect { get :new }.to raise_error
    end

    it "does not show if the petition is not open" do
      allow(Petition).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      expect(Petition).to receive(:visible).and_return(Petition)
      expect { get :new, :petition_id => 1 }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'sets the stage to "signer"' do
      get :new, :petition_id => 1
      expect(assigns(:stage_manager).stage).to eq 'signer'
    end
  end

  describe "#create" do
    let!(:petition) { FactoryGirl.create(:open_petition) }

    let(:signature_params) do
      {
        :name => 'John Mcenroe',
        :email => 'john@example.com',
        :uk_citizenship => "1",
        :postcode => 'SE3 4LL',
        :country => 'United Kingdom'
      }
    end

    def do_post(options = {})
      params = {
        :stage => 'replay-email',
        :move => 'next',
        :signature => signature_params,
        :petition_id => petition.id
      }
      post :create, params.merge(options)
    end

    context 'managing the "move" parameter' do
      it 'defaults to "next" if it is not present' do
        do_post :move => nil
        expect(controller.params['move']).to eq 'next'
      end

      it 'defaults to "next" if it is present but blank' do
        do_post :move => ''
        expect(controller.params['move']).to eq 'next'
      end

      it 'overrides it to "next" if it is present but not "next" or "back"' do
        do_post :move => 'blah'
        expect(controller.params['move']).to eq 'next'
      end

      it 'overrides it to "next" if "move:next" is present' do
        do_post :move => 'blah', :'move:next' => 'Onwards!'
        expect(controller.params['move']).to eq 'next'
      end

      it 'overrides it to "back" if "move:back" is present' do
        do_post :move => 'blah', :'move:back' => 'Backwards!'
        expect(controller.params['move']).to eq 'back'
      end

      it 'overrides it to "next" if both "move:next" and "move:back" are present' do
        do_post :move => 'blah',  :'move:next' => 'Onwards!', :'move:back' => 'Backwards!'
        expect(controller.params['move']).to eq 'next'
      end
    end

    context "valid input" do
      it "emails the signer" do
        do_post
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to eq(["john@example.com"])
      end

      it "creates a new signature object" do
        expect { do_post }.to change(Signature, :count).from(1).to(2)
      end

      it "creates a new signature object even when email has whitespace" do
        expect { do_post(:email => ' john@example.com ') }.to change(Signature, :count).from(1).to(2)
      end

      it "overrides the petition no matter what has been provided in the signature params" do
        signature_params[:petition_id] = '1111'
        do_post
        expect(assigns(:stage_manager).signature.petition).to eq(petition)
      end

      it "has not changed the default TRUE value for notify_by_email" do
        do_post
        expect(assigns(:stage_manager).signature.notify_by_email).to eq(true)
      end

      it "redirects to a thank you page" do
        do_post
        expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}/signatures/thank-you")
      end
    end

    context "invalid input" do
      it "renders :new again for empty email" do
        signature_params[:email] = ''
        do_post
        expect(response).to render_template(:new)
      end

      it "should not create a new signature" do
        signature_params[:email] = ''
        expect { do_post }.not_to change(Signature, :count)
      end

      it "has stage of 'signer' if there are errors on name, uk_citizenship, postcode or country" do
        do_post :signature => signature_params.merge(:name => '')
        expect(assigns[:stage_manager].stage).to eq 'signer'
        do_post :signature => signature_params.merge(:uk_citizenship => '')
        expect(assigns[:stage_manager].stage).to eq 'signer'
        do_post :signature => signature_params.merge(:postcode => '')
        expect(assigns[:stage_manager].stage).to eq 'signer'
        do_post :signature => signature_params.merge(:country => '')
        expect(assigns[:stage_manager].stage).to eq 'signer'
      end

      it "has stage of 'replay-email' if there are errors on email and we came from 'replay-email' stage" do
        new_signature_params = signature_params.merge(:email => 'foo@')
        do_post :stage => 'replay-email',
                :signature => new_signature_params
        expect(assigns[:stage_manager].stage).to eq 'replay-email'
      end

      it "has stage of 'creator' if there are errors on email and we came from 'signer' stage" do
        new_signature_params = signature_params.merge(:email => 'foo@')
        do_post :stage => 'signer',
                :signature => new_signature_params
        expect(assigns[:stage_manager].stage).to eq 'signer'
      end
    end

    context "signature with same name/email/postcode" do
      let(:signature_params) do
        {
          name: 'Joe Blow',
          email: 'jb@example.com',
          postcode: 'SE3 4LL',
          uk_citizenship: '1',
          country: 'United Kingdom'
        }
      end

      context "unvalidated signature already exists" do
        before do
          FactoryGirl.create(:pending_signature, signature_params.merge(petition_id: petition.id))
        end

        it "same name/email/postcode does not change count of signatures" do
          expect{ do_post }.to_not change(Signature, :count)
        end

        it "same email/postcode changes count of signatures" do
          signature_params[:name] = 'Susan Blow'
          expect{ do_post }.to change(Signature, :count).by(1)
        end

        it "sends email to signer" do
          ActionMailer::Base.deliveries.clear
          do_post
          email = ActionMailer::Base.deliveries.last
          expect(email.to).to eq(["jb@example.com"])
        end

        it "sends to thank you page" do
          do_post
          expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}/signatures/thank-you")
        end
      end

      context "validated signature already exists" do
        before do
          FactoryGirl.create(:validated_signature, signature_params.merge(petition_id: petition.id))
        end

        it "sends to :new for same name/email/postcode" do
          do_post
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe '#unsubscribe' do
    before do
      @petition = FactoryGirl.create(:petition)
      @signature = FactoryGirl.create(:signature, :petition => @petition)
    end

    context "with valid unsubscription token" do
      before do
        get :unsubscribe, :id => @signature.id, :unsubscribe_token => @signature.unsubscribe_token
        @signature.reload
      end

      it 'unsubscribes signer' do
        expect(@signature.notify_by_email).to be_falsey
      end

      it 'renders a view stating that unsubscribing was successfull' do
        expect(response).to render_template(:successfully_unsubscribed)
      end
    end

    context "with invalid parameters" do
      context "with invalid unsubscription token" do
        before do
          get :unsubscribe, :id => @signature.id, :unsubscribe_token => 'INVALID_TOKEN'
        end

        it 'does not unsubscribe signer' do
          expect(@signature.notify_by_email).to be_truthy
        end

        it 'renders a template that indicates that unsubscription failed' do
          expect(response.body).to render_template(:failed_to_unsubscribe)
        end
      end

      context "with non-matching signature id and unsubscription token" do
        before do
          anohter_signature = FactoryGirl.create(:signature, :petition => @petition)
          get :unsubscribe, :id => @signature.id, :unsubscribe_token =>  anohter_signature.unsubscribe_token
        end

        it 'does not unsubscribe signer' do
          expect(@signature.notify_by_email).to be_truthy
        end

        it 'renders a template that indicates that unsubscription failed' do
          expect(response.body).to render_template(:failed_to_unsubscribe)
        end
      end

      context "with already unsubscribed signer" do
        it 'renders a template stating that the signer has already unsubscribed' do
          @signature.notify_by_email = false
          @signature.save

          get :unsubscribe, :id => @signature.id, :unsubscribe_token => @signature.unsubscribe_token
          expect(response.body).to render_template(:already_unsubscribed)
        end
      end
    end
  end
end
