require 'rails_helper'

describe Admin::PetitionsController do
  include ActiveJob::TestHelper

  before :each do
    creator_signature = FactoryGirl.create(:signature, :email => 'john@example.com')
    @petition = FactoryGirl.create(:sponsored_petition, :creator_signature => creator_signature)
  end

  describe "not logged in" do
    describe "GET 'edit'" do
      it "should redirect to the login page" do
        get :edit, :id => @petition.id
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end

    describe "GET 'threshold'" do
      it "should redirect to the login page" do
        get :threshold
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end

    describe "GET 'index'" do
      it "should redirect to the login page" do
        get :index
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end

    describe "GET 'show'" do
      it "should redirect to the login page" do
        get :show, :id => @petition.id
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    before :each do
      @user = FactoryGirl.create(:moderator_user, :force_password_reset => true)
      login_as(@user)
    end

    it "should redirect to edit profile page" do
      expect(@user.has_to_change_password?).to be_truthy
      get :edit, :id => @petition.id
      expect(response).to redirect_to("https://petition.parliament.uk/admin/profile/#{@user.id}/edit")
    end
  end

  describe "logged in as moderator user" do
    before :each do
      @user = FactoryGirl.create(:moderator_user)
      login_as(@user)

      @p1 = FactoryGirl.create(:open_petition)
      @p1.update_attribute(:signature_count, 11)
      @p2 = FactoryGirl.create(:open_petition)
      @p2.update_attribute(:signature_count, 10)
      @p3 = FactoryGirl.create(:open_petition)
      @p3.update_attribute(:signature_count, 9)
      @p4 = FactoryGirl.create(:closed_petition)
      @p4.update_attribute(:signature_count, 20)
      FactoryGirl.create(:system_setting, :key => SystemSetting::THRESHOLD_SIGNATURE_COUNT, :value => "10")
    end

    it "should return all petitions that have more than the threshold number of signatures in ascending count order" do
      get :threshold
      expect(assigns[:petitions]).to eq([@p2, @p1, @p4])
    end

    it "should assign petition" do
      get :edit_response, :id => @p1.id
      expect(assigns[:petition]).to eq(@p1)
    end

    context 'update internal response' do
      it "should update internal response and response required flag" do
        patch :update_response, :id => @p1.id, :petition => {:internal_response => 'This is popular', :response_required => '1'}
        @p1.reload
        expect(@p1.internal_response).to eq('This is popular')
        expect(@p1.response_required).to be_truthy
      end
    end

    context "update_response" do
      def do_patch(options = {})
        patch :update_response, :id => @p1.id, :petition => { :response => 'Doh!', :response_summary => 'Summary', :email_signees => '1'}.merge(options)
      end
      it "should update response and email signees flag with true" do
        do_patch
        assert_enqueued_jobs 1
        expect(response).to redirect_to("https://petition.parliament.uk/admin/petitions")
        @p1.reload
        expect(@p1.response).to eq('Doh!')
        expect(@p1.email_requested_at).not_to be_nil
      end

      it "should update response and email signees flag with false" do
        do_patch(:email_signees => '0')
        assert_enqueued_jobs 0
        @p1.reload
        expect(@p1.response).to eq('Doh!')
        expect(@p1.email_requested_at).to be_nil
      end

      it "should fail to update response and email signees flag due to validation error" do
        do_patch(:response => '', :email_signees => '1')
        assert_enqueued_jobs 0
        expect(response).to be_success
        @p1.reload
        expect(@p1.email_requested_at).to be_nil
      end

      context "email out threshold update response" do
        before :each do
          signature = FactoryGirl.create(:signature, :name => 'Jason', :email => 'jason@example.com', :state => Petition::VALIDATED_STATE, :notify_by_email => true)
          @petition = FactoryGirl.create(:open_petition, :title => 'Make me the PM', :creator_signature => signature)
          6.times { |i| FactoryGirl.create(:signature, :name => "Jason #{i}", :email => "jason_valid_notify_#{i}@example.com",
                                :state => Petition::VALIDATED_STATE, :notify_by_email => true, :petition => @petition) }
          3.times { |i| FactoryGirl.create(:signature, :name => "Jason #{i}", :email => "jason_valid_#{i}@example.com",
                                :state => Petition::VALIDATED_STATE, :notify_by_email => false, :petition => @petition) }
          @petition.reload
          @petition.signatures.last.save! # needed in order to get the signature count updated
          2.times { |i| FactoryGirl.create(:signature, :name => "Jason #{i}", :email => "jason_invalid_#{i}@example.com",
                                :state => Petition::PENDING_STATE, :notify_by_email => true, :petition => @petition) }
          Petition.update_all_signature_counts
        end

        it "should setup a delayed job" do
          assert_enqueued_jobs 1 do
            patch :update_response, :id => @petition.id, :petition => { :response => 'Doh!', :response_summary => 'Summary', :email_signees => '1'}
          end
        end

        it "should set the email signees flag to false when the job runs" do
          perform_enqueued_jobs do
            patch :update_response, :id => @petition.id, :petition => { :response => 'Doh!', :response_summary => 'Summary', :email_signees => '1'}
            @petition.reload
            expect(@petition.email_requested_at).not_to be_nil
            @petition.signatures.validated.notify_by_email.each do |signature|
              expect(signature.last_emailed_at).to eq(@petition.email_requested_at)
            end
          end
        end

        it "should email out to the validated signees who have opted in when the delayed job runs" do
          perform_enqueued_jobs do
            no_emails = ActionMailer::Base.deliveries.length
            patch :update_response, :id => @petition.id, :petition => { :response => 'Doh!', :response_summary => 'Summary', :email_signees => '1'}
            expect(ActionMailer::Base.deliveries.length - no_emails).to eq(7)
            expect(ActionMailer::Base.deliveries[no_emails].to).to eq(["jason@example.com"])
            expect(ActionMailer::Base.deliveries[no_emails].subject).to match(/The petition 'Make me the PM' has reached 10 signatures/)
            expect(ActionMailer::Base.deliveries.last.to).to eq(["jason_valid_notify_5@example.com"])
          end
        end
      end
    end
  end

  describe "logged in as sysadmin" do
    before :each do
      @user = FactoryGirl.create(:sysadmin_user)
      login_as(@user)
    end

    context "index" do
      let(:petitions) { double.as_null_object }

      before do
        allow(Petition).to receive(:moderated).and_return(petitions)
      end

      it "shows all moderated petitions" do
        expect(Petition).to receive(:moderated).and_return(petitions)
        get :index
      end

      it "optionally filters by state" do
        expect(petitions).to receive(:for_state).with('open').and_return(petitions)
        get :index, :state => 'open'
      end
    end

    context "edit" do
      it "should be successful" do
        get :edit, :id => @petition.id
        expect(assigns[:petition]).to eq(@petition)
      end

      it "should be unsuccessful for a petition that is not validated" do
        petition = FactoryGirl.create(:open_petition)
        expect {
          get :edit, :id => petition.id
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "show" do
      it "should be successful" do
        get :show, :id => @petition.id
        expect(assigns(:petition)).to eq(@petition)
      end
    end

    context "update" do
      def do_post(options ={})
        patch :update, {:id => @petition.id}.merge(options)
      end

      it "should be unsuccessful for a petition that is not validated" do
        petition = FactoryGirl.create(:open_petition)
        expect {
          do_post(:id => petition.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context "publishing" do
        let(:now) { Chronic.parse("1 Jan 2011") }
        def set_up
          allow(Time).to receive(:current).and_return(now)
          do_post :commit => 'Publish this petition'
          @petition.reload
        end

        it "opens the petition" do
          set_up
          expect(@petition.state).to eq(Petition::OPEN_STATE)
        end

        it "sets the open date to now" do
          set_up
          expect(@petition.open_at.change(usec: 0)).to eq(now.change(usec: 0))
        end

        it "sets the closed date to the end of the day on the date #{AppConfig.petition_duration} months from now" do
          set_up
          expect(@petition.closed_at.change(usec: 0)).to eq( (now + AppConfig.petition_duration.months).end_of_day.change(usec: 0) )
        end

        it "redirects to the main admin page" do
          set_up
          expect(response).to redirect_to("https://petition.parliament.uk/admin")
        end

        it "sends an email to the petition creator" do
          set_up
          email = ActionMailer::Base.deliveries.last
          expect(email.subject).to match(/Your e-petition has been published/)
        end
      end

      context "reject" do
        it "reject successfully" do
          do_post :commit => 'Reject', :petition => {:rejection_code => 'duplicate'}
          @petition.reload
          expect(@petition.state).to eq(Petition::REJECTED_STATE)
          expect(@petition.rejection_code).to eq('duplicate')
          expect(response).to redirect_to("https://petition.parliament.uk/admin")
        end

        it "reject with 'offensive' causes petition to be hidden" do
          do_post :commit => 'Reject', :petition => {:rejection_code => 'offensive'}
          @petition.reload
          expect(@petition.state).to eq(Petition::HIDDEN_STATE)
        end

        it "reject with 'libellous' causes petition to be hidden" do
          do_post :commit => 'Reject', :petition => {:rejection_code => 'libellous'}
          @petition.reload
          expect(@petition.state).to eq(Petition::HIDDEN_STATE)
        end

        it "sends an email to the petition creator" do
          do_post :commit => 'Reject', :petition => {:rejection_code => 'libellous'}
          email = ActionMailer::Base.deliveries.last
          expect(email.from).to eq(["no-reply@example.gov"])
          expect(email.to).to eq(["john@example.com"])
          expect(email.subject).to match(/e-petition has been rejected/)
        end

        it "sends an email to validated petition sponsors" do
          validated_sponsor_1  = FactoryGirl.create(:sponsor, :validated, petition: @petition)
          validated_sponsor_2  = FactoryGirl.create(:sponsor, :validated, petition: @petition)
          do_post :commit => 'Reject', :petition => {:rejection_code => 'libellous'}
          email = ActionMailer::Base.deliveries.last
          expect(email.bcc).to match_array([validated_sponsor_1.signature.email, validated_sponsor_2.signature.email])
        end

        it "does not send an email to pending petition sponsors" do
          pending_sponsor  = FactoryGirl.create(:sponsor, :pending, petition: @petition)
          do_post :commit => 'Reject', :petition => {:rejection_code => 'libellous'}
          email = ActionMailer::Base.deliveries.last
          expect(email.bcc).not_to include([pending_sponsor.signature.email])
        end

        it "reject fails when no reason code given" do
          do_post :commit => 'Reject', :petition => {:rejection_code => nil}
          @petition.reload
          expect(@petition.state).to eq(Petition::SPONSORED_STATE)
        end
      end

      describe "take down" do
        context "an open petition" do
          before { @petition.publish! }
          it "succeeds" do
            @petition.save
            post :take_down, :id => @petition.id, :petition => {:rejection_code => 'offensive' }
            @petition.reload
            expect(@petition.state).to eq(Petition::HIDDEN_STATE)
            expect(@petition.rejection_code).to eq('offensive')
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
            expect(@petition.state).to eq(Petition::HIDDEN_STATE)
          end
        end
      end
    end
  end
end
