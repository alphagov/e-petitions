require 'rails_helper'

RSpec.describe SignaturesController, type: :controller do
  describe "#verify" do
    context "signature of user who is not the petition's creator" do
      let(:petition) { FactoryGirl.create(:petition) }
      let(:signature) { FactoryGirl.create(:pending_signature, :petition => petition) }

      let(:constituency) do
        FactoryGirl.create(
          :constituency, external_id: '1234', name: 'Cities of London and Westminster'
        )
      end

      before do
        allow(Constituency).to receive(:find_by_postcode).with("SW1A1AA").and_return(constituency)
      end

      it "redirects to the petition signed page" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(assigns[:signature]).to eq(signature)
        expect(response).to redirect_to("https://petition.parliament.uk/signatures/#{signature.to_param}/signed?token=#{signature.perishable_token}")
      end

      it "raises exception if id not found" do
        expect do
          get :verify, :id => signature.id + 1, :token => signature.perishable_token
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises exception if token not found" do
        expect do
          get :verify, :id => signature.id, :token => "#{signature.perishable_token}a"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'signature to be verified is a sponsor' do
      let(:petition) { FactoryGirl.create(:petition) }
      let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
      let(:signature) { sponsor.create_signature(FactoryGirl.attributes_for(:pending_signature, petition: petition)) }

      around do |example|
        perform_enqueued_jobs do
          example.call
        end
      end

      it "redirects to the petition sponsored page" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(assigns[:signature]).to eq(signature)
        expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{petition.sponsor_token}/sponsored")
      end

      it "sets petition state to validated" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(petition.reload.state).to eq(Petition::VALIDATED_STATE)
      end

      it "sets state to validated" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(signature.reload.state).to eq(Signature::VALIDATED_STATE)
      end

      it "sets petition creator signature state to validated" do
        get :verify, :id => signature.id, :token => signature.perishable_token
        expect(petition.creator_signature.reload.state).to eq(Signature::VALIDATED_STATE)
      end

      it 'sends email notification to the petition creator' do
        get :verify, :id => signature.id, :token => signature.perishable_token
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to eq([petition.creator_signature.email])
      end

      it 'updates petition sponsored state' do
        allow(Signature).to receive(:find).with(signature.to_param).and_return signature
        allow(signature).to receive(:petition).and_return petition
        get :verify, :id => signature.id, :token => signature.perishable_token
      end

      it "raises exception if id not found" do
        expect do
          get :verify, :id => signature.id + 1, :token => signature.perishable_token
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises exception if token not found" do
        expect do
          get :verify, :id => signature.id, :token => "#{signature.perishable_token}a"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      context "and the petition is published" do
        before do
          petition.publish
          petition.reload
          ActionMailer::Base.deliveries.clear
        end

        it "redirects to the petition signed page" do
          get :verify, :id => signature.id, :token => signature.perishable_token
          expect(assigns[:signature]).to eq(signature)
          expect(response).to redirect_to("https://petition.parliament.uk/signatures/#{signature.to_param}/signed?token=#{signature.perishable_token}")
        end

        it "does not send an email to the creator" do
          perform_enqueued_jobs do
            get :verify, :id => signature.id, :token => signature.perishable_token
            expect(ActionMailer::Base.deliveries).to be_empty
          end
        end
      end
    end

    context "when the petition is closed" do
      let(:petition) { FactoryGirl.build(:closed_petition) }
      let(:signature) { FactoryGirl.create(:pending_signature, :petition => petition) }

      it "redirects to the petition page" do
        get :verify, id: signature.id, token: signature.perishable_token
        expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}")
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryGirl.create(:petition) }
      let(:signature) { FactoryGirl.create(:fraudulent_signature, petition: petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, id: signature.id, token: signature.perishable_token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryGirl.create(:petition) }
      let(:signature) { FactoryGirl.create(:invalidated_signature, petition: petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, id: signature.id, token: signature.perishable_token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#signed" do
    let(:petition) { FactoryGirl.create(:petition) }

    def make_signed_request(token = nil)
      get :signed, id: signature.to_param, token: (token || signature.perishable_token)
    end

    context 'for validated signatures' do
      let(:signature) { FactoryGirl.create(:validated_signature, petition: petition) }

      it "raises exception if token does not match the signature" do
        expect { make_signed_request "not_a_valid_token" }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'signer has not seen the signed page before' do
        before do
          signature.update! seen_signed_confirmation_page: false
        end

        it 'exposes the signature and its petition' do
          make_signed_request
          expect(assigns['signature']).to eq signature
          expect(assigns['petition']).to eq petition
        end

        it 'marks the signature as the signer having seen the confirmation page' do
          make_signed_request
          expect(signature.reload.seen_signed_confirmation_page).to be_truthy
        end

        it 'renders the signed template' do
          make_signed_request
          expect(response).to be_success
          expect(response).to render_template('signatures/signed')
        end
      end

      context 'signer has already seen the signed page (clicking link in the email again)' do
        before do
          signature.mark_seen_signed_confirmation_page!
        end

        it 'keeps the signature as the signer having seen the confirmation page' do
          expect { make_signed_request }.not_to change(signature.reload, :seen_signed_confirmation_page)
        end

        it 'redirects to the petition show page' do
          make_signed_request
          expect(response).to redirect_to "https://petition.parliament.uk/petitions/#{petition.id}"
        end
      end
    end

    context 'for unvalidated signatures' do
      let(:signature) { FactoryGirl.create(:pending_signature, petition: petition) }

      it "redirects to the signature verify page" do
        make_signed_request
        expect(response).to redirect_to("https://petition.parliament.uk/signatures/#{signature.id}/verify?token=#{signature.perishable_token}")
      end

      it "raises exception if token does not match" do
        expect { make_signed_request "not_a_valid_token" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryGirl.create(:petition) }
      let(:signature) { FactoryGirl.create(:fraudulent_signature, petition: petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, id: signature.id, token: signature.perishable_token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryGirl.create(:petition) }
      let(:signature) { FactoryGirl.create(:invalidated_signature, petition: petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, id: signature.id, token: signature.perishable_token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "new" do
    let(:petition) { FactoryGirl.build(:petition) }

    before do
      allow(Petition).to receive_messages(:visible => Petition)
      allow(Petition).to receive(:find).with('1').and_return(petition)
      allow(petition).to receive(:id).and_return(1)
    end

    it "assigns a new signature with the given petition" do
      get :new, :petition_id => 1
      expect(assigns(:stage_manager).signature.petition).to eq(petition)
    end

    it "sets the location code to be GB" do
      get :new, :petition_id => 1
      expect(assigns(:stage_manager).signature.location_code).to eq 'GB'
    end

    it "finds the given petition" do
      get :new, :petition_id => 1
      expect(assigns(:petition)).to eq petition
    end

    it "raises if petition id is not supplied" do
      allow(Petition).to receive(:find).with("").and_raise(ActiveRecord::RecordNotFound)
      expect { get :new, :petition_id => ""}.to raise_error(ActiveRecord::RecordNotFound)
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

    context "when the petition is closed" do
      let(:petition) { FactoryGirl.create(:closed_petition) }

      it "redirects to the petition page" do
        get :new, petition_id: 1
        expect(response).to redirect_to("https://petition.parliament.uk/petitions/1")
      end
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
        :location_code => 'GB'
      }
    end

    let(:constituency) do
      FactoryGirl.create(
        :constituency, external_id: '54321', name: 'Greater Signatureton'
      )
    end

    def do_post(options = {})
      params = {
        :stage => 'replay-email',
        :move => 'next',
        :signature => signature_params,
        :petition_id => petition.id
      }.merge(options)

      allow(Constituency).to receive(:find_by_postcode).with("SE34LL").and_return(constituency)

      perform_enqueued_jobs do
        post :create, params
      end
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

      it "sets the constituency_id on the signature, based on the postcode" do
        do_post
        expect(assigns(:stage_manager).signature.constituency_id).to eq "54321"
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

      it "does not create a new signature" do
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
        do_post :signature => signature_params.merge(:location_code => '')
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
          location_code: 'GB'
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

      context "when a race condition occurs" do
        let(:exception) { ActiveRecord::RecordNotUnique.new("PG::UniqueViolation") }
        before do
          FactoryGirl.create(:validated_signature, signature_params.merge(petition_id: petition.id))
          allow_any_instance_of(Signature).to receive(:save).and_raise(exception)
        end

        it "redirects to the thank you page" do
          do_post(stage: 'done')
          expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}/signatures/thank-you")
        end
      end
    end

    context "when the petition is closed" do
      let!(:petition) { FactoryGirl.create(:closed_petition) }

      it "redirects to the petition page" do
        do_post
        expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}")
      end
    end
  end

  describe '#unsubscribe' do
    let(:signature) { double(:signature, id: 1, unsubscribe_token: "token") }
    let(:petition) { double(:petition) }

    before do
      expect(Signature).to receive(:find).with("1").and_return(signature)
      expect(signature).to receive(:petition).and_return(petition)
      allow(signature).to receive(:fraudulent?).and_return(false)
      allow(signature).to receive(:invalidated?).and_return(false)
    end


    context "when the signature is validated" do
      before do
        expect(signature).to receive(:unsubscribe!).with("token")
      end

      it "renders the action template" do
        get :unsubscribe, id: "1", token: "token"
        expect(response.body).to render_template(:unsubscribe)
      end
    end

    context "when the signature is fraudulent" do
      before do
        expect(signature).to receive(:fraudulent?).and_return(true)
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          get :unsubscribe, id: "1", token: "token"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is invalidated" do
      before do
        expect(signature).to receive(:invalidated?).and_return(true)
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          get :unsubscribe, id: "1", token: "token"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
