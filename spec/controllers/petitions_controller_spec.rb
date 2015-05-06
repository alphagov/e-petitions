require 'rails_helper'

describe PetitionsController do
  describe "new" do

    with_ssl do
      it "should respond to /petitions/new" do
        expect({:get => "/petitions/new"}).to route_to({:controller => "petitions", :action => "new"})
        expect(new_petition_path).to eq '/petitions/new'
      end

      it "should assign a new petition without a creator_signature" do
        get :new
        expect(assigns[:petition]).not_to be_nil
        expect(assigns[:petition].creator_signature).to be_nil
      end

      it "should assign departments" do
        department1 = FactoryGirl.create(:department, :name => 'DFID')
        department2 = FactoryGirl.create(:department, :name => 'Treasury')

        get :new

        expect(assigns[:departments]).to eq [department1, department2]
      end

      it "is on stage 'petition'" do
        get :new
        expect(assigns[:petition].stage).to eq 'petition';
      end

      it "fills in the title if given" do
        title = "my fancy new title"
        get :new, :title => title
        expect(assigns[:petition].title).to eq title
      end
    end
  end

  describe "create" do
    before :each do
      @department = FactoryGirl.create(:department)
      @sponsor_emails = (1..AppConfig.sponsor_count_min).map { |i| "sponsor#{i}@example.com" }.join("\n")
      @creator_signature_attributes = {:name => 'John Mcenroe', :email => 'john@example.com', :email_confirmation => 'john@example.com',
                                       :address => 'Rose Cottage', :town => 'London', :postcode => 'SE3 4LL', :country => 'United Kingdom', :uk_citizenship => '1', :terms_and_conditions => '1'}
    end

    def do_post(options = {})
      post :create, :petition => {:title => 'Save the planet', :action => 'Limit temperature rise at two degrees', :description => 'Global warming is upon us', :duration => "12",
        :department_id => @department.id, :sponsor_emails => @sponsor_emails, :creator_signature => @creator_signature_attributes}.merge(options)
    end

    with_ssl do
      it "should respond to posts to /petitions/new" do
        expect({:post => "/petitions/new"}).to route_to({:controller => "petitions", :action => "create"})
        expect(create_petition_path).to eq('/petitions/new')
      end

      context "valid post" do
        it "should successfully create a new petition and a signature" do
          do_post
          petition = Petition.find_by_title!('Save the planet')
          expect(petition.creator_signature).not_to be_nil
          expect(response).to redirect_to(thank_you_petition_path(petition, secure: true))
        end

        it "should successfully create a new petition and a signature even when email has white space either end" do
          do_post(:creator_signature => @creator_signature_attributes.merge(:email => ' john@example.com '))
          petition = Petition.find_by_title!('Save the planet')
        end

        it "should strip a petition title on petition creation" do
          do_post(:title => ' Save the planet')
          petition = Petition.find_by_title!('Save the planet')
        end

        it "should send verification email to petition's creator" do
          email = ActionMailer::Base.deliveries.last
          expect(email.from).to eq(["no-reply@example.gov"])
          expect(email.to).to eq(["john@example.com"])
          expect(email.subject).to match(/Email address confirmation/)
        end

        it "should successfully point the signature at the petition" do
          do_post
          petition = Petition.find_by_title!('Save the planet')
          expect(petition.creator_signature.petition).to eq(petition)
        end

        it "should set user's ip address on signature" do
          do_post
          petition = Petition.find_by_title!('Save the planet')
          expect(petition.creator_signature.ip_address).to eq("0.0.0.0")
        end

        it "should not be able to set the state of a new petition" do
          do_post :state => Petition::VALIDATED_STATE
          petition = Petition.find_by_title!('Save the planet')
          expect(petition.state).to eq(Petition::PENDING_STATE)
        end

        it "should not be able to set the state of a new signature" do
          do_post :creator_signature => @creator_signature_attributes.merge(:state => Signature::VALIDATED_STATE)
          petition = Petition.find_by_title!('Save the planet')
          expect(petition.creator_signature.state).to eq(Signature::PENDING_STATE)
        end

        it "should set notify_by_email to true on the creator signature" do
          do_post
          expect(Petition.find_by_title!('Save the planet').creator_signature.notify_by_email).to be_truthy
        end
      end

      context "invalid post" do
        it "should not create a new petition if no title is given" do
          do_post :title => ''
          expect(Petition.find_by_title('Save the planet')).to be_nil
          expect(assigns[:petition].errors[:title]).not_to be_blank
          expect(response).to be_success
        end

        it "should not create a new petition if email is invalid" do
          do_post :creator_signature => @creator_signature_attributes.merge(:email => 'not much of an email')
          expect(Petition.find_by_title('Save the planet')).to be_nil
          expect(response).to be_success
        end

        it "should not create a new petition if address is blank" do
          do_post :creator_signature => @creator_signature_attributes.merge(:address => '')
          expect(Petition.find_by_title('Save the planet')).to be_nil
          expect(response).to be_success
        end

        it "should not create a new petition if UK citizenship is not confirmed" do
          do_post :creator_signature => @creator_signature_attributes.merge(:uk_citizenship => '0')
          expect(Petition.find_by_title('Save the planet')).to be_nil
          expect(response).to be_success
        end

        it "should assign departments if submission fails" do
          do_post :title => ''
          expect(assigns[:departments]).to eq([@department])
        end

        it "has stage of 'petition' if there are errors on title, department or description" do
          do_post :title => ''
          expect(assigns[:petition].stage).to eq 'petition'
          do_post :department_id => nil
          expect(assigns[:petition].stage).to eq 'petition'
          do_post :description => ''
          expect(assigns[:petition].stage).to eq 'petition'
        end

        it "has stage of 'creator' if there are errors on name, email, email_confirmation, uk_citizenship, address, town, postcode or country" do
          do_post :creator_signature => @creator_signature_attributes.merge(:name => '')
          expect(assigns[:petition].stage).to eq 'creator'
          do_post :creator_signature => @creator_signature_attributes.merge(:email => '')
          expect(assigns[:petition].stage).to eq 'creator'
          do_post :creator_signature => @creator_signature_attributes.merge(:email => 'dave@example.com', :email_confirmation => 'laura@example.com')
          expect(assigns[:petition].stage).to eq 'creator'
          do_post :creator_signature => @creator_signature_attributes.merge(:uk_citizenship => '')
          expect(assigns[:petition].stage).to eq 'creator'
          do_post :creator_signature => @creator_signature_attributes.merge(:address => '')
          expect(assigns[:petition].stage).to eq 'creator'
          do_post :creator_signature => @creator_signature_attributes.merge(:town => '')
          expect(assigns[:petition].stage).to eq 'creator'
          do_post :creator_signature => @creator_signature_attributes.merge(:postcode => '')
          expect(assigns[:petition].stage).to eq 'creator'
          do_post :creator_signature => @creator_signature_attributes.merge(:country => '')
          expect(assigns[:petition].stage).to eq 'creator'
        end

        it "has stage of 'sponsors' if there are errors on sponsor_emails" do
          do_post :sponsor_emails => 'blah@'
          expect(assigns[:petition].stage).to eq 'sponsors'
        end

        it "has stage of 'submit' if there are errors on terms_and_conditions" do
          do_post :creator_signature => @creator_signature_attributes.merge(:terms_and_conditions => '0')
          expect(assigns[:petition].stage).to eq 'submit'
        end
      end
    end
  end

  describe "show" do
    let(:petition) { double }
    it "assigns the given petition" do
      allow(Petition).to receive_message_chain(:visible, :find => petition)
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

  describe "index" do
    let(:page) { "1" }
    let(:visible) { double.as_null_object }
    before(:each) do
      allow(Petition).to receive_messages(:visible => visible)
    end

    it "Assigns a paginated petition list of the visible petitions" do
      expect(visible).to receive(:paginate).with(:page => page.to_i, :per_page => 20)
      get :index, :page => page
    end

    it "Sanitises the page param" do
      expect(visible).to receive(:paginate).with(:page => 400, :per_page => 20)
      get :index, :page => '400.'
    end


    it "Sets the petition state to 'open'" do
      get :index
      expect(assigns(:petition_search).state).to eq 'open'
    end

    it "Sets state counts to the petition visible state counts" do
      allow(Petition).to receive(:for_state).with('open').and_return(double(:count, :count => 1))
      allow(Petition).to receive(:for_state).with('closed').and_return(double(:count, :count => 2))
      allow(Petition).to receive(:for_state).with('rejected').and_return(double(:count, :count => 4))
      get :index
      expect(assigns(:petition_search).state_counts).to eq({ 'open' => 1, 'closed' => 2, 'rejected' => 4 })
    end

    it "sorting by name sorts alphabetically" do
      expect(SearchOrder).to receive(:sort_order).with(hash_including(:sort => 'title'), anything).and_return(['foo', 'asc'])
      expect(visible).to receive(:order).with("foo asc")
      get :index, :order => 'asc', :sort => 'title'
    end
  end

  describe "GET #check" do
    it "is successful" do
      get :check
      expect(response).to be_success
    end
  end

  describe "GET #check_results" do
    it_should_behave_like "it searches petitions", :check_results, :search, 10
  end

  describe "POST #resend_confirmation_email" do
    let!(:petition){ FactoryGirl.create(:open_petition) }
    let!(:email) { 'suzie@example.com' }

    before(:each) do
      allow(Petition).to receive_message_chain(:visible, :find).and_return(petition)
    end

    it "finds the petition" do
      expect(Petition.visible).to receive(:find).with(petition.id.to_s)
      post :resend_confirmation_email, :id => petition.id, :confirmation_email => email
    end

    it "renders the email resent view" do
      post :resend_confirmation_email, :id => petition.id, :confirmation_email => email
      expect(response).to render_template :resend_confirmation_email
    end

    let(:confirmer) { double }
    it "asks the petition to resend the confirmation email" do
      expect(SignatureConfirmer).to receive(:new).with(petition, email, PetitionMailer, Authlogic::Regex.email).and_return(confirmer)
      expect(confirmer).to receive(:confirm!)
      post :resend_confirmation_email, :id => petition.id, :confirmation_email => email
    end
  end
end
