require 'rails_helper'

describe SignaturesController do
  describe "verify" do
    context "signature of user who is not the petition's creator" do
      before :each do
        petition = FactoryGirl.create(:petition)
        @signature = FactoryGirl.create(:signature, :petition => petition)
      end

      it "should respond to /signatures/:id/verify/:token" do
        expect({:get => "/signatures/#{@signature.id}/verify/#{@signature.perishable_token}"}).
          to route_to({:controller => "signatures", :action => "verify", :id => @signature.id.to_s, :token => @signature.perishable_token})
        expect(verify_signature_path(@signature, @signature.perishable_token)).to eq("/signatures/#{@signature.id}/verify/#{@signature.perishable_token}")
      end

      it "should redirect to the petitions page" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        expect(assigns[:signature]).to eq(@signature)
        expect(response).to redirect_to(signed_petition_signature_path(@signature.petition))
      end

      it "should not set petition state to validated" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        expect(Petition.find(@signature.petition.id).state).to eq(Petition::PENDING_STATE)
      end

      it "should set creator signature state to validated and set token to nil" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        signature = Signature.find(@signature.id)
        expect(signature.state).to eq(Signature::VALIDATED_STATE)
        expect(signature.perishable_token).to be_nil
      end

      it "should raise exception if id not found" do
        expect do
          get :verify, :id => @signature.id + 1, :token => @signature.perishable_token
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should raise exception if token not found" do
        expect do
          petition = FactoryGirl.create(:petition)
          @signature = FactoryGirl.create(:signature, :petition => petition, :state => Signature::PENDING_STATE)
          get :verify, :id => @signature.id, :token => "#{@signature.perishable_token}a"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "signature to be verified is petition creator's" do
      before :each do
        @petition = FactoryGirl.create(:petition)
        @signature = @petition.creator_signature
      end

      it "should render successfully if petition creator verifies email address" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        expect(assigns[:signature]).to eq(@signature)
        expect(response).to be_success
      end

      it "should set petition state to validated" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        expect(Petition.find(@petition.id).state).to eq(Petition::VALIDATED_STATE)
      end

      it "should set creator signature state to validated and set token to nil" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        signature = Signature.find(@signature.id)
        expect(signature.state).to eq(Signature::VALIDATED_STATE)
        expect(signature.perishable_token).to be_nil
      end

      it "sends emails to petition sponsors after verification" do
        @petition.sponsors.clear
        @petition.sponsors.create(email: "test@test.com")

        get :verify, :id => @signature.id, :token => @signature.perishable_token

        Delayed::Job.last.payload_object.perform

        email = ActionMailer::Base.deliveries.last
        expect(email.from).to eq(["no-reply@example.gov"])
        expect(email.to).to eq(["test@test.com"])
        expect(email.cc).to eq([@petition.creator_signature.email])
        expect(email.subject).to eq("Parliament petitions - #{@petition.creator_signature.name} would like your support")
      end
    end
  end

  describe "new" do
    let(:petition) { double }
    let(:signature) { double }

    before do
      allow(Petition).to receive_messages(:visible => Petition)
      allow(Petition).to receive(:find).with('1').and_return(petition)
      allow(Signature).to receive_messages(:new => signature)
    end

    with_ssl do
      it "assigns a new signature with the given petition" do
        expect(Signature).to receive(:new).with(hash_including(:petition => petition)).and_return(signature)
        get :new, :petition_id => 1
        expect(assigns(:signature)).to eq(signature)
      end

      it "sets the country to be UK" do
        expect(Signature).to receive(:new).with(hash_including(:country => "United Kingdom")).and_return(signature)
        get :new, :petition_id => 1
      end

      it "finds the given petition" do
        get :new, :petition_id => 1
        expect(assigns(:petition)).not_to be_nil
      end

      it "raises if petition id is not supplied" do
        expect { get :new }.to raise_error
      end

      it "does not show if the petition is not open" do
        allow(Petition).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        expect(Petition).to receive(:visible).and_return(Petition)
        expect { get :new, :petition_id => 1 }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "create" do
    let!(:petition) { FactoryGirl.create(:open_petition) }

    let(:signature_params) do
      {
        :name => 'John Mcenroe',
        :email => 'john@example.com',
        :uk_citizenship => "1",
        :postcode => 'SE3 4LL',
        :country => 'UK'
      }
    end

    def do_post(options = {})
      post :create, :signature => signature_params.merge(options), :petition_id => petition.id
    end

    with_ssl do
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

        it "overrides the petition no matter what has been passed in" do
          do_post(:petition_id => 1111)
          expect(assigns(:signature).petition).to eq(petition)
        end

        it "has not changed the default TRUE value for notify_by_email" do
          do_post
          expect(assigns(:signature).notify_by_email).to eq(true)
        end

        it "redirects to a thank you page" do
          do_post
          expect(response).to redirect_to(thank_you_petition_signature_path(petition))
        end
      end
      
      context "invalid input" do
        it "renders :new again for empty email" do
          do_post(:email => "")
          expect(response).to render_template(:new)
        end
        
        it "should not create a new signature" do
          expect { do_post(:email => "") }.not_to change(Signature, :count)
        end
      end


      ### How to reduce code? use behaves_like?
      ### good way to split up the contexts?
      ### how to make one assertion per test? email and redirect are currently linked?
      context "signature with same name/email/postcode" do
        let(:custom_params) {{ name: 'Joe Blow', email: 'jb@example.com',
                               email_confirmation: 'jb@example.com', postcode: 'SE3 4LL' }}
        let(:unvalidated_signature) { FactoryGirl.build(:pending_signature, name: 'Joe Blow', email:'jb@example.com',
                                                        email_confirmation:'jb@example.com', postcode: 'SE3 4LL',
                                                        petition_id: petition.id) }
        let(:validated_signature) { FactoryGirl.build(:validated_signature, name: 'Joe Blow', email:'jb@example.com',
                                                      email_confirmation:'jb@example.com', postcode: 'SE3 4LL',
                                                      petition_id: petition.id) }
        
        context "unvalidated signature already exists" do
          before { unvalidated_signature.save }
          
          it "same name/email/postcode does not change count of signatures" do
            expect{ do_post(custom_params) }.to_not change(Signature, :count)
          end
          
          it "same email/postcode changes count of signatures" do
            expect{ do_post(custom_params.merge( { name: 'Susan Blow' })) }.to change(Signature, :count).by(1)
          end
          
          it "sends email to signer" do
            ActionMailer::Base.deliveries.clear
            do_post(custom_params)
            email = ActionMailer::Base.deliveries.last
            expect(email.to).to eq(["jb@example.com"])
          end
          
          it "sends to thank you page" do
            do_post(custom_params)
            expect(response).to redirect_to(thank_you_petition_signature_path(petition))
          end
        end

        context "validated signature already exists" do
          before { validated_signature.save }
          
          it "sends to :new for same name/email/postcode" do
            do_post(custom_params)
            expect(response).to render_template(:new)
          end
        end
      end
    end
  end
end
