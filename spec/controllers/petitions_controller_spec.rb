require 'rails_helper'

RSpec.describe PetitionsController, type: :controller do
  describe "new" do
    it "should assign a new stage_manager with a petition" do
      get :new
      expect(assigns[:stage_manager]).not_to be_nil
      expect(assigns[:stage_manager].petition).not_to be_nil
    end

    it "is on stage 'petition'" do
      get :new
      expect(assigns[:stage_manager].stage).to eq 'petition';
    end

    it "fills in the action if given as petition_action" do
      action = "my fancy new action"
      get :new, :petition_action => action
      expect(assigns[:stage_manager].petition.action).to eq action
    end
  end

  describe "create" do
    let(:creator_signature_attributes) do
      {
        :name => 'John Mcenroe', :email => 'john@example.com',
        :postcode => 'SE3 4LL', :location_code => 'GB',
        :uk_citizenship => '1'
      }
    end
    let(:petition_attributes) do
      {
        :action => 'Save the planet',
        :background => 'Limit temperature rise at two degrees',
        :additional_details => 'Global warming is upon us',
        :creator_signature => creator_signature_attributes
      }
    end

    let(:constituency) do
      FactoryGirl.create(
        :constituency, external_id: '54321', name: 'North Creatorshire'
      )
    end

    def do_post(options = {})
      params = {
        :stage => 'replay-email',
        :move => 'next',
        :petition => petition_attributes
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

    context "valid post" do
      it "should successfully create a new petition and a signature" do
        do_post
        petition = Petition.find_by_action!('Save the planet')
        expect(petition.creator_signature).not_to be_nil
        expect(response).to redirect_to("https://petition.parliament.uk/petitions/#{petition.id}/thank-you")
      end

      it "should successfully create a new petition and a signature even when email has white space either end" do
        creator_signature_attributes[:email] = ' john@example.com '
        do_post
        petition = Petition.find_by_action!('Save the planet')
      end

      it "should strip a petition action on petition creation" do
        petition_attributes[:action] = ' Save the planet'
        do_post
        petition = Petition.find_by_action!('Save the planet')
      end

      it "should send gather sponsors email to petition's creator" do
        ActionMailer::Base.deliveries.clear
        do_post
        email = ActionMailer::Base.deliveries.detect { |email| email.subject =~ /Action required: Petition/ }
        expect(email).to be_present
        expect(email.from).to eq(["no-reply@petition.parliament.uk"])
        expect(email.to).to eq(["john@example.com"])
      end

      it "should successfully point the signature at the petition" do
        do_post
        petition = Petition.find_by_action!('Save the planet')
        expect(petition.creator_signature.petition).to eq(petition)
      end

      it "should set user's ip address on signature" do
        do_post
        petition = Petition.find_by_action!('Save the planet')
        expect(petition.creator_signature.ip_address).to eq("0.0.0.0")
      end

      it "should not be able to set the state of a new petition" do
        petition_attributes[:state] = Petition::VALIDATED_STATE
        do_post
        petition = Petition.find_by_action!('Save the planet')
        expect(petition.state).to eq(Petition::PENDING_STATE)
      end

      it "should not be able to set the state of a new signature" do
        creator_signature_attributes[:state] = Signature::VALIDATED_STATE
        do_post
        petition = Petition.find_by_action!('Save the planet')
        expect(petition.creator_signature.state).to eq(Signature::PENDING_STATE)
      end

      it "should set notify_by_email to true on the creator signature" do
        do_post
        expect(Petition.find_by_action!('Save the planet').creator_signature.notify_by_email).to be_truthy
      end

      it "sets the constituency_id on the creator signature, based on the postcode" do
        do_post
        expect(Petition.find_by_action!('Save the planet').creator_signature.constituency_id).to eq("54321")
      end

      context "invalid post" do
        it "should not create a new petition if no action is given" do
          petition_attributes[:action] = ''
          do_post
          expect(Petition.find_by_action('Save the planet')).to be_nil
          expect(assigns[:stage_manager].petition.errors[:action]).not_to be_blank
          expect(response).to be_success
        end

        it "should not create a new petition if email is invalid" do
          creator_signature_attributes[:email] = 'not much of an email'
          do_post
          expect(Petition.find_by_action('Save the planet')).to be_nil
          expect(response).to be_success
        end

        it "should not create a new petition if UK citizenship is not confirmed" do
          creator_signature_attributes[:uk_citizenship] = '0'
          do_post
          expect(Petition.find_by_action('Save the planet')).to be_nil
          expect(response).to be_success
        end

        it "has stage of 'petition' if there are errors on action, background, or additional_details" do
          do_post :petition => petition_attributes.merge(:action => '')
          expect(assigns[:stage_manager].stage).to eq 'petition'
          do_post :petition => petition_attributes.merge(:background => '')
          expect(assigns[:stage_manager].stage).to eq 'petition'
          do_post :petition => petition_attributes.merge(:additional_details => 'a'*801)
          expect(assigns[:stage_manager].stage).to eq 'petition'
        end

        it "has stage of 'creator' if there are errors on name, uk_citizenship, postcode or country" do
          do_post :petition => petition_attributes.merge(:creator_signature => creator_signature_attributes.merge(:name => ''))
          expect(assigns[:stage_manager].stage).to eq 'creator'
          do_post :petition => petition_attributes.merge(:creator_signature => creator_signature_attributes.merge(:uk_citizenship => ''))
          expect(assigns[:stage_manager].stage).to eq 'creator'
          do_post :petition => petition_attributes.merge(:creator_signature => creator_signature_attributes.merge(:postcode => ''))
          expect(assigns[:stage_manager].stage).to eq 'creator'
          do_post :petition => petition_attributes.merge(:creator_signature => creator_signature_attributes.merge(:location_code => ''))
          expect(assigns[:stage_manager].stage).to eq 'creator'
        end

        it "has stage of 'replay-email' if there are errors on email and we came from 'replay-email' stage" do
          new_creator_signature_attribtues = creator_signature_attributes.merge(:email => 'foo@')
          new_petition_attributes = petition_attributes.merge(:creator_signature => new_creator_signature_attribtues)
          do_post :stage => 'replay-email',
                  :petition => new_petition_attributes
          expect(assigns[:stage_manager].stage).to eq 'replay-email'
        end

        it "has stage of 'creator' if there are errors on email and we came from 'creator' stage" do
          new_creator_signature_attribtues = creator_signature_attributes.merge(:email => 'foo@')
          new_petition_attributes = petition_attributes.merge(:creator_signature => new_creator_signature_attribtues)
          do_post :stage => 'creator',
                  :petition => new_petition_attributes
          expect(assigns[:stage_manager].stage).to eq 'creator'
        end
      end
    end
  end

  describe "show" do
    let(:petition) { double }
    it "assigns the given petition" do
      allow(petition).to receive(:in_moderation?).and_return(false)
      allow(petition).to receive(:moderated?).and_return(true)
      allow(Petition).to receive_message_chain(:show, :find => petition)

      get :show, :id => 1
      expect(assigns(:petition)).to eq(petition)
    end

    it "does not allow hidden petitions to be shown" do
      expect {
        allow(Petition).to receive_message_chain(:visible, :find).and_raise ActiveRecord::RecordNotFound
        get :show, :id => 1
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #index" do
    context 'when no state param is provided' do
      it "is successful" do
        get :index
        expect(response).to be_success
      end

      it "exposes a search scoped to the all facet" do
        get :index
        expect(assigns(:petitions).scope).to eq :all
      end
    end

    context 'when a state param is provided' do
      context 'but it is not a public facet from the locale file' do
        it 'redirects to itself with state=all' do
          get :index, state: 'awaiting_monkey'
          expect(response).to redirect_to 'https://petition.parliament.uk/petitions?state=all'
        end

        it 'preserves other params when it redirects' do
          get :index, q: 'what is clocks', state: 'awaiting_monkey'
          expect(response).to redirect_to 'https://petition.parliament.uk/petitions?q=what+is+clocks&state=all'
        end
      end

      context 'and it is a public facet from the locale file' do
        it 'is successful' do
          get :index, state: 'open'
          expect(response).to be_success
        end

        it "exposes a search scoped to the state param" do
          get :index, state: 'open'
          expect(assigns(:petitions).scope).to eq :open
        end
      end
    end
  end

  describe "GET #check" do
    it "is successful" do
      get :check
      expect(response).to be_success
    end
  end
end
