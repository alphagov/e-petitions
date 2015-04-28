require 'spec_helper'

describe Admin::PetitionsController do
  before :each do
    creator_signature = Factory(:signature, :email => 'john@example.com')
    @petition = Factory(:validated_petition, :creator_signature => creator_signature, :duration => "3")
  end

  describe "not logged in" do
    with_ssl do
      describe "GET 'edit'" do
        it "should redirect to the login page" do
          get :edit, :id => @petition.id
          response.should redirect_to(admin_login_path)
        end
      end

      describe "GET 'threshold'" do
        it "should redirect to the login page" do
          get :threshold
          response.should redirect_to(admin_login_path)
        end
      end

      describe "GET 'index'" do
        it "should redirect to the login page" do
          get :index
          response.should redirect_to(admin_login_path)
        end
      end

      describe "GET 'show'" do
        it "should redirect to the login page" do
          get :show, :id => @petition.id
          response.should redirect_to(admin_login_path)
        end
      end
    end
  end

  context "logged in as admin user but need to reset password" do
    before :each do
      @user = Factory.create(:admin_user, :force_password_reset => true)
      login_as(@user)
    end

    with_ssl do
      it "should redirect to edit profile page" do
        @user.has_to_change_password?.should be_true
        get :edit, :id => @petition.id
        response.should redirect_to(edit_admin_profile_path(@user))
      end
    end
  end

  context "logged in as admin" do
    before :each do
      @user = Factory.create(:admin_user)
      @treasury = Factory(:department, :name => 'Treasury')
      @user.departments << @treasury
      login_as(@user)
      @p1 = Factory(:open_petition, :department => @treasury)
      @p2 = Factory(:open_petition)
      @p3 = Factory(:closed_petition)
    end

    with_ssl do
      it "should show moderated petitions assigned to the treasury" do
        get :index
        response.should be_success
        assigns[:petitions].should == [@p1]
      end

      it "should redirect to all petitions on update of internal response" do
        put :update_internal_response, :id => @p1.id, :petition => {:internal_response => 'This is popular', :response_required => '1'}
        response.should redirect_to(admin_petitions_path)
      end

      it "should update internal response and response required flag" do
        put :update_internal_response, :id => @p1.id, :petition => {:internal_response => 'This is popular', :response_required => '1'}
        @p1.reload
        @p1.internal_response.should == 'This is popular'
        @p1.response_required.should be_true
      end
    end
  end

  describe "logged in as threshold user" do
    before :each do
      @user = Factory.create(:threshold_user)
      login_as(@user)

      @p1 = Factory(:open_petition)
      @p1.update_attribute(:signature_count, 11)
      @p2 = Factory(:open_petition)
      @p2.update_attribute(:signature_count, 10)
      @p3 = Factory(:open_petition)
      @p3.update_attribute(:signature_count, 9)
      @p4 = Factory(:closed_petition)
      @p4.update_attribute(:signature_count, 20)
      Factory(:system_setting, :key => SystemSetting::THRESHOLD_SIGNATURE_COUNT, :value => "10")
    end

    with_ssl do
      it "should return all petitions that have more than the threshold number of signatures in ascending count order" do
        get :threshold
        assigns[:petitions].should == [@p2, @p1, @p4]
      end

      it "should assign petition" do
        get :edit_response, :id => @p1.id
        assigns[:petition].should == @p1
      end

      context "update_response" do
        def do_put(options = {})
          put :update_response, :id => @p1.id, :petition => { :response => 'Doh!', :email_signees => '1'}.merge(options)
        end
        it "should update response and email signees flag with true" do
          Delayed::Job.should_receive(:enqueue)
          do_put
          response.should redirect_to(threshold_admin_petitions_path)
          @p1.reload
          @p1.response.should == 'Doh!'
          @p1.email_requested_at.should_not be_nil
        end

        it "should update response and email signees flag with false" do
          Delayed::Job.should_not_receive(:enqueue)
          do_put(:email_signees => '0')
          @p1.reload
          @p1.response.should == 'Doh!'
          @p1.email_requested_at.should be_nil
        end

        it "should fail to update response and email signees flag due to validation error" do
          Delayed::Job.should_not_receive(:enqueue)
          do_put(:response => '', :email_signees => '1')
          response.should be_success
          @p1.reload
          @p1.email_requested_at.should be_nil
        end

        context "email out threshold update response" do
          before :each do
            signature = Factory(:signature, :name => 'Jason', :email => 'jason@example.com', :state => Petition::VALIDATED_STATE, :notify_by_email => true)
            @petition = Factory(:open_petition, :title => 'Make me the PM', :creator_signature => signature)
            6.times { |i| Factory(:signature, :name => "Jason #{i}", :email => "jason_valid_notify_#{i}@example.com",
                                  :state => Petition::VALIDATED_STATE, :notify_by_email => true, :petition => @petition) }
            3.times { |i| Factory(:signature, :name => "Jason #{i}", :email => "jason_valid_#{i}@example.com",
                                  :state => Petition::VALIDATED_STATE, :notify_by_email => false, :petition => @petition) }
            @petition.reload
            @petition.signatures.last.save! # needed in order to get the signature count updated
            2.times { |i| Factory(:signature, :name => "Jason #{i}", :email => "jason_invalid_#{i}@example.com",
                                  :state => Petition::PENDING_STATE, :notify_by_email => true, :petition => @petition) }
            Petition.update_all_signature_counts
          end

          it "should setup a delayed job" do
            lambda do
              put :update_response, :id => @petition.id, :petition => { :response => 'Doh!', :email_signees => '1'}
            end.should change(Delayed::Job, :count).by(1)
          end

          it "should set the email signees flag to false when the job runs" do
            put :update_response, :id => @petition.id, :petition => { :response => 'Doh!', :email_signees => '1'}
            @petition.reload
            @petition.email_requested_at.should_not be_nil
            Delayed::Job.all[0].payload_object.perform
            @petition.reload
            @petition.signatures.validated.notify_by_email.each do |signature|
              signature.last_emailed_at.should == @petition.email_requested_at
            end
          end

          it "should email out to the validated signees who have opted in when the delayed job runs" do
            no_emails = ActionMailer::Base.deliveries.length
            put :update_response, :id => @petition.id, :petition => { :response => 'Doh!', :email_signees => '1'}
            Delayed::Job.all[0].payload_object.perform
            (ActionMailer::Base.deliveries.length - no_emails).should == 7
            ActionMailer::Base.deliveries[no_emails].to.should == ["jason@example.com"]
            ActionMailer::Base.deliveries[no_emails].subject.should match(/The petition 'Make me the PM' has reached 10 signatures/)
            ActionMailer::Base.deliveries.last.to.should == ["jason_valid_notify_5@example.com"]
          end

          it "should not email out to the validated signees if emails have already gone out" do
            no_emails = ActionMailer::Base.deliveries.length
            put :update_response, :id => @petition.id, :petition => { :response => 'Doh!', :email_signees => '1'}
            @petition.reload
            Petition.find(@petition.id).update_attribute(:email_signees, false)
            Signature.update_all(:last_emailed_at => @petition.email_requested_at)
            Delayed::Job.all[0].payload_object.perform
            (ActionMailer::Base.deliveries.length - no_emails).should == 0
          end
        end
      end
    end
  end

  describe "logged in as sysadmin" do
    before :each do
      @department = Factory.create(:department)
      @user = Factory.create(:sysadmin_user)
      login_as(@user)
    end

    without_ssl do
      context "edit" do
        it "should redirect to ssl" do
          get :edit, :id => @petition.id
          response.should redirect_to(edit_admin_petition_url(@petition, :protocol => 'https'))
        end
      end
    end

    with_ssl do
      context "index" do
        let(:petitions) { double.as_null_object }

        before do
          Petition.stub(:moderated).and_return(petitions)
        end

        it "shows all moderated petitions for the current user's department" do
          Petition.should_receive(:moderated).and_return(petitions)
          get :index
        end

      it "optionally filters by state" do
          petitions.should_receive(:for_state).with('open').and_return(petitions)
          get :index, :state => 'open'
        end

      end

      context "edit" do
        it "should be successful" do
          get :edit, :id => @petition.id
          assigns[:petition].should == @petition
        end

        it "should be unsuccessful for a petition that is not validated" do
          petition = Factory(:open_petition)
          lambda {
            get :edit, :id => petition.id
          }.should raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "show" do
        it "should be successful" do
          get :show, :id => @petition.id
          assigns(:petition).should == @petition
        end
      end

      context "update" do
        def do_post(options ={})
          put :update, {:id => @petition.id}.merge(options)
        end

        it "should be unsuccessful for a petition that is not validated" do
          petition = Factory(:open_petition)
          lambda {
            do_post(:id => petition.id)
          }.should raise_error(ActiveRecord::RecordNotFound)
        end

        context "publishing" do
          let(:now) { Chronic.parse("1 Jan 2011") }
          def set_up
            Time.zone.stub!(:now).and_return(now)
            do_post :commit => 'Publish this petition'
            @petition.reload
          end

          it "opens the petition" do
            set_up
            @petition.state.should == Petition::OPEN_STATE
          end

          it "sets the open date to now" do
            set_up
            @petition.open_at.should == now
          end

          it "sets the closed date to 3 months from now" do
            set_up
            @petition.closed_at.should == now + 3.months
          end

          it "sets the closed date to 12 months from now" do
            @petition.update_attribute(:duration, "12")
            set_up
            @petition.closed_at.should == now + 12.months
          end

          it "redirects to the main admin page" do
            set_up
            response.should redirect_to(admin_root_path)
          end

          it "sends an email to the petition creator" do
            set_up
            email = ActionMailer::Base.deliveries.last
            email.subject.should match(/Your e-petition has been published/)
          end
        end

        it "re-assign successfully" do
          @department = Factory(:department)
          do_post :commit => 'Re-assign', :petition => {:department_id => @department.id}
          @petition.reload
          @petition.department.should == @department
          response.should redirect_to(admin_root_path)
        end

        context "reject" do
          it "reject successfully" do
            do_post :commit => 'Reject', :petition => {:rejection_code => 'duplicate'}
            @petition.reload
            @petition.state.should == Petition::REJECTED_STATE
            @petition.rejection_code.should == 'duplicate'
            response.should redirect_to(admin_root_path)
          end

          it "reject with 'offensive' causes petition to be hidden" do
            do_post :commit => 'Reject', :petition => {:rejection_code => 'offensive'}
            @petition.reload
            @petition.state.should == Petition::HIDDEN_STATE
          end

          it "reject with 'libellous' causes petition to be hidden" do
            do_post :commit => 'Reject', :petition => {:rejection_code => 'libellous'}
            @petition.reload
            @petition.state.should == Petition::HIDDEN_STATE
          end

          it "sends an email to the petition creator" do
            email = ActionMailer::Base.deliveries.last
            email.from.should == ["no-reply@example.gov"]
            email.to.should == ["john@example.com"]
            email.subject.should match(/Your e-petition has been rejected/)
          end

          it "reject fails when no reason code given" do
            do_post :commit => 'Reject', :petition => {:rejection_code => nil}
            @petition.reload
            @petition.state.should == Petition::VALIDATED_STATE
          end
        end

        describe "take down" do
          context "an open petition" do
            before do
              @petition.state = Petition::OPEN_STATE
              @petition.open_at = Time.zone.now
              @petition.closed_at = @petition.duration.to_i.months.from_now
              @petition.save!
            end
            it "succeeds" do
              @petition.save
              post :take_down, :id => @petition.id, :petition => {:rejection_code => 'offensive' }
              @petition.reload
              @petition.state.should == Petition::HIDDEN_STATE
              @petition.rejection_code.should == 'offensive'
            end
          end

          context "a rejected (but visible) petition" do
            before do
              @petition.state = Petition::REJECTED_STATE
              @petition.rejection_code = 'offensive'
              @petition.save!
            end

            it "succeeds" do
              post :take_down, :id => @petition.id, :petition => {:rejection_code => 'offensive' }
              @petition.reload
              @petition.state.should == Petition::HIDDEN_STATE
            end
          end
        end
      end
    end
  end
end
