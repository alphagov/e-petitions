require 'spec_helper'

describe SignaturesController do
  describe "verify" do
    context "signature of user who is not the petition's creator" do
      before :each do
        petition = Factory(:petition)
        @signature = FactoryGirl.create(:signature, :petition => petition)
      end

      it "should respond to /signatures/:id/verify/:token" do
        {:verify => "/petitions/#{@signature.id}/verify/#{@signature.perishable_token}"}.should
               route_to({:controller => "signatures", :action => "verify"})
        verify_signature_path(@signature, @signature.perishable_token).should == "/signatures/#{@signature.id}/verify/#{@signature.perishable_token}"
      end

      it "should redirect to the petitions page" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        assigns[:signature].should == @signature
        response.should redirect_to(signed_petition_signature_path(@signature.petition))
      end

      it "should not set petition state to validated" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        Petition.find(@signature.petition.id).state.should == Petition::PENDING_STATE
      end

      it "should set creator signature state to validated and set token to nil" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        signature = Signature.find(@signature.id)
        signature.state.should == Signature::VALIDATED_STATE
        signature.perishable_token.should be_nil
      end

      it "should raise exception if id not found" do
        lambda do
          get :verify, :id => @signature.id + 1, :token => @signature.perishable_token
        end.should raise_error(ActiveRecord::RecordNotFound)
      end

      it "should raise exception if token not found" do
        lambda do
          petition = Factory(:petition)
          @signature = FactoryGirl.create(:signature, :petition => petition, :state => Signature::PENDING_STATE)
          get :verify, :id => @signature.id, :token => "#{@signature.perishable_token}a"
        end.should raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "signature to be verified is petition creator's" do
      before :each do
        @petition = Factory(:petition)
        @signature = @petition.creator_signature
      end

      it "should render successfully if petition creator verifies email address" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        assigns[:signature].should == @signature
        response.should be_success
      end

      it "should set petition state to validated" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        Petition.find(@petition.id).state.should == Petition::VALIDATED_STATE
      end

      it "should set creator signature state to validated and set token to nil" do
        get :verify, :id => @signature.id, :token => @signature.perishable_token
        signature = Signature.find(@signature.id)
        signature.state.should == Signature::VALIDATED_STATE
        signature.perishable_token.should be_nil
      end
    end
  end

  describe "new" do
    let(:petition) { mock }
    let(:signature) { mock }

    before do
      Petition.stub(:visible => Petition)
      Petition.stub(:find).with(1).and_return(petition)
      Signature.stub(:new => signature)
    end

    without_ssl do
      it "should redirect to ssl" do
        get :new, :petition_id => 1
        response.should redirect_to(new_petition_signature_url(@petition, :protocol => 'https'))
      end
    end

    with_ssl do
      it "assigns a new signature with the given petition" do
        Signature.should_receive(:new).with(hash_including(:petition => petition)).and_return(signature)
        get :new, :petition_id => 1
        assigns(:signature).should == signature
      end

      it "sets the country to be UK" do
        Signature.should_receive(:new).with(hash_including(:country => "United Kingdom")).and_return(signature)
        get :new, :petition_id => 1
      end

      it "finds the given petition" do
        get :new, :petition_id => 1
        assigns(:petition).should_not be_nil
      end

      it "raises if petition id is not supplied" do
        lambda { get :new }.should raise_error
      end

      it "does not show if the petition is not open" do
        Petition.stub(:find).and_raise(ActiveRecord::RecordNotFound)
        Petition.should_receive(:visible).and_return(Petition)
        lambda { get :new, :petition_id => 1 }.should raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "create" do
    let!(:petition) { Factory(:open_petition) }

    let(:signature_params) {{:name => 'John Mcenroe', :email => 'john@example.com', :email_confirmation => 'john@example.com',
      :uk_citizenship => "1", :terms_and_conditions => "1", :humanity => true,
      :address => 'Rose Cottage', :town => 'London', :postcode => 'SE3 4LL',
      :country => 'UK'}}

    before(:each) do
      Captcha.stub!(:verify => true)
    end

    def do_post(options = {})
      post :create, :signature => signature_params.merge(options), :petition_id => petition.id
    end

    with_ssl do
      context "valid input" do
        it "emails the petition creator" do
          do_post
          email = ActionMailer::Base.deliveries.last
          email.to.should == ["john@example.com"]
        end

        it "creates a new signature object" do
          lambda { do_post }.should change(Signature, :count).from(1).to(2)
        end

        it "creates a new signature object even when email has whitespace" do
          lambda { do_post(:email => ' john@example.com ') }.should change(Signature, :count).from(1).to(2)
        end

        it "overrides the petition no matter what has been passed in" do
          do_post(:petition_id => 1111)
          assigns(:signature).petition.should == petition
        end

        it "redirects to a thank you page" do
          do_post
          response.should redirect_to(thank_you_petition_signature_path(petition))
        end
      end

      context "invalid input" do
        it "renders :new again" do
          do_post(:email => "")
          response.should render_template(:new)
        end

        it "should not create a new signature" do
          lambda { do_post(:email => "") }.should_not change(Signature, :count)
        end
      end
    end
  end
end
