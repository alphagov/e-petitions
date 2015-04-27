require 'spec_helper'

describe PetitionsController do
  describe "new" do

    without_ssl do
      it "should redirect to ssl" do
        get :new
        response.should redirect_to(new_petition_url(:protocol => 'https'))
      end
    end

    with_ssl do
      it "should respond to /petitions/new" do
        {:get => "/petitions/new"}.should route_to({:controller => "petitions", :action => "new"})
        new_petition_path.should == '/petitions/new'
      end

      it "should assign a new petition and creator signature" do
        get :new
        assigns[:petition].should_not be_nil
        assigns[:petition].creator_signature.should_not be_nil
      end

      it "should assign departments" do
        department1 = Factory.create(:department, :name => 'DFID')
        department2 = Factory.create(:department, :name => 'Treasury')

        get :new

        assigns[:departments].should == [department1, department2]
      end

      it "creator signature should default the country to UK" do
        get :new
        assigns[:petition].creator_signature.country.should == 'United Kingdom'
      end

      it "should assign @start_on_section to 0" do
        get :new
        assigns[:start_on_section].should == 0;
      end

      it "fills in the title if given" do
        title = "my fancy new title"
        get :new, :title => title
        assigns[:petition].title.should == title
      end
    end
  end

  describe "create" do
    before :each do
      @department = Factory(:department)
      @creator_signature_attributes = {:name => 'John Mcenroe', :email => 'john@example.com', :email_confirmation => 'john@example.com',
                                      :address => 'Rose Cottage', :town => 'London', :postcode => 'SE3 4LL', :country => 'UK', :uk_citizenship => '1', :terms_and_conditions => '1'}
      Captcha.stub!(:verify => true)
    end

    def do_post(options = {})
      post :create, :petition => {:title => 'Save the planet', :description => 'Global warming is upon us', :duration => "12",
        :department_id => @department.id, :creator_signature_attributes => @creator_signature_attributes}.merge(options)
    end

    with_ssl do
      it "should respond to posts to /petitions/new" do
        {:post => "/petitions/new"}.should route_to({:controller => "petitions", :action => "create"})
        create_petition_path.should == '/petitions/new'
      end

      context "valid post" do
        it "should successfully create a new petition and a signature" do
          do_post
          petition = Petition.find_by_title!('Save the planet')
          petition.creator_signature.should_not be_nil
          response.should redirect_to(thank_you_petition_path(petition))
        end

        it "should successfully create a new petition and a signature even when email has white space either end" do
          do_post(:creator_signature_attributes => @creator_signature_attributes.merge(:email => ' john@example.com '))
          petition = Petition.find_by_title!('Save the planet')
        end

        it "should strip a petition title on petition creation" do
          do_post(:title => ' Save the planet')
          petition = Petition.find_by_title!('Save the planet')
        end

        it "should send verification email to petition's creator" do
          email = ActionMailer::Base.deliveries.last
          email.from.should == ["no-reply@example.gov"]
          email.to.should == ["john@example.com"]
          email.subject.should match(/Email address confirmation/)
        end

        it "should successfully point the signature at the petition" do
          do_post
          petition = Petition.find_by_title!('Save the planet')
          petition.creator_signature.petition.should == petition
        end

        it "should set user's ip address on signature" do
          do_post
          petition = Petition.find_by_title!('Save the planet')
          petition.creator_signature.ip_address.should == "0.0.0.0"
        end

        it "should not be able to set the state of a new petition" do
          do_post :state => Petition::VALIDATED_STATE
          petition = Petition.find_by_title!('Save the planet')
          petition.state.should == Petition::PENDING_STATE
        end

        it "should not be able to set the state of a new signature" do
          do_post :creator_signature_attributes => @creator_signature_attributes.merge(:state => Signature::VALIDATED_STATE)
          petition = Petition.find_by_title!('Save the planet')
          petition.creator_signature.state.should == Signature::PENDING_STATE
        end

        it "should not set notify_by_email to true on the creator signature" do
          do_post
          Petition.find_by_title!('Save the planet').creator_signature.notify_by_email.should be_true
        end
      end

      context "invalid post" do
        it "should not create a new petition if no title is given" do
          do_post :title => ''
          Petition.find_by_title('Save the planet').should be_nil
          assigns[:petition].errors_on(:title).should_not be_blank
          response.should be_success
        end

        it "should not create a new petition if email is invalid" do
          do_post :creator_signature_attributes => @creator_signature_attributes.merge(:email => 'not much of an email')
          Petition.find_by_title('Save the planet').should be_nil
          response.should be_success
        end

        it "should not create a new petition if address is blank" do
          do_post :creator_signature_attributes => @creator_signature_attributes.merge(:address => '')
          Petition.find_by_title('Save the planet').should be_nil
          response.should be_success
        end

        it "should not create a new petition if UK citizenship is not confirmed" do
          do_post :creator_signature_attributes => @creator_signature_attributes.merge(:uk_citizenship => '0')
          Petition.find_by_title('Save the planet').should be_nil
          response.should be_success
        end

        it "should assign departments if submission fails" do
          do_post :title => ''
          assigns[:departments].should == [@department]
        end

        it "should add an error to @petition if the recaptcha is not valid" do
          Captcha.stub!(:verify => false)
          do_post
          Petition.find_by_title('Save the planet').should be_nil
          assigns[:petition].creator_signature.errors[:humanity].should == ["The captcha was not filled in correctly."]
        end

        it "should assign start_on_section to 0 if there are errors on title, department or description" do
          do_post :title => ''
          assigns[:start_on_section].should == 0
          do_post :department_id => nil
          assigns[:start_on_section].should == 0
          do_post :description => ''
          assigns[:start_on_section].should == 0
        end
        it "should assign start_on_section to 1 if there are errors on name, email, is_uk_citizen, address, town, postcode or country" do
          do_post :creator_signature_attributes => @creator_signature_attributes.merge(:name => '')
          assigns[:start_on_section].should == 1
          do_post :creator_signature_attributes => @creator_signature_attributes.merge(:email => '')
          assigns[:start_on_section].should == 1
          do_post :is_uk_citizen => '0'
          assigns[:start_on_section].should == 1
          do_post :creator_signature_attributes => @creator_signature_attributes.merge(:address => '')
          assigns[:start_on_section].should == 1
          do_post :creator_signature_attributes => @creator_signature_attributes.merge(:town => '')
          assigns[:start_on_section].should == 1
          do_post :creator_signature_attributes => @creator_signature_attributes.merge(:postcode => '')
          assigns[:start_on_section].should == 1
          do_post :creator_signature_attributes => @creator_signature_attributes.merge(:country => '')
          assigns[:start_on_section].should == 1
        end
        it "should assign start_on_section to 2 if there are errors on recaptcha" do
          Captcha.stub!(:verify => false)
          do_post
          assigns[:start_on_section].should == 2
        end
      end
    end
  end

  describe "show" do
    let(:petition) { mock }
    it "assigns the given petition" do
      Petition.stub_chain(:visible, :find => petition)
      get :show, :id => 1
      assigns(:petition).should == petition
    end

    it "does not allow hidden petitions to be shown" do
      lambda do
        Petition.stub_chain(:visible, :find).and_raise ActiveRecord::RecordNotFound
        get :show, :id => 1
      end.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "index" do
    let(:page) { "1" }
    let(:visible) { double.as_null_object }
    before(:each) do
      Petition.stub(:visible => visible)
    end

    it "Assigns a paginated petition list of the visible petitions" do
      visible.should_receive(:paginate).with(:page => page.to_i, :per_page => 20)
      get :index, :page => page
    end

    it "Sanitises the page param" do
      visible.should_receive(:paginate).with(:page => 400, :per_page => 20)
      get :index, :page => '400.'
    end


    it "Sets the petition state to 'open'" do
      get :index
      assigns(:petition_search).state.should == 'open'
    end

    it "Sets state counts to the petition visible state counts" do
      Petition.stub(:for_state).with('open').and_return(double(:count, :count => 1))
      Petition.stub(:for_state).with('closed').and_return(double(:count, :count => 2))
      Petition.stub(:for_state).with('rejected').and_return(double(:count, :count => 4))
      get :index
      assigns(:petition_search).state_counts.should == { 'open' => 1, 'closed' => 2, 'rejected' => 4 }
    end

    it "sorting by name sorts alphabetically" do
      SearchOrder.should_receive(:sort_order).with(hash_including(:sort => 'title'), anything).and_return(['foo', 'asc'])
      visible.should_recieve(:order).with("foo asc")
      get :index, :order => 'asc', :sort => 'title'
    end
  end

  describe "GET #check" do
    it "is successful" do
      get :check
      response.should be_success
    end
  end

  describe "GET #check_results" do
    it_should_behave_like "it searches petitions", :check_results, :search, 10
  end

  describe "POST #resend_confirmation_email" do
    let!(:petition){ Factory(:open_petition) }
    let!(:email) { 'suzie@example.com' }

    before(:each) do
      Petition.stub_chain(:visible, :find).and_return(petition)
    end

    it "finds the petition" do
      Petition.visible.should_receive(:find).with(petition.id)
      post :resend_confirmation_email, :id => petition.id, :confirmation_email => email
    end

    it "renders the email resent view" do
      post :resend_confirmation_email, :id => petition.id, :confirmation_email => email
      response.should render_template :resend_confirmation_email
    end

    let(:confirmer) { double }
    it "asks the petition to resend the confirmation email" do
      SignatureConfirmer.should_receive(:new).with(petition, email, PetitionMailer, Authlogic::Regex.email).and_return(confirmer)
      confirmer.should_receive(:confirm!)
      post :resend_confirmation_email, :id => petition.id, :confirmation_email => email
    end
  end
end
