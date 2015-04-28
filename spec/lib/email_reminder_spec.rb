require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EmailReminder do
  describe "admin_email_reminders" do
    def set_up(date)
      Time.zone.stub(:now).and_return(date)
      @d1 = FactoryGirl.create(:department)
      @d2 = FactoryGirl.create(:department)
      @d3 = FactoryGirl.create(:department)
      @user1 = FactoryGirl.create(:admin_user, :email => 'peter@directgov.uk')
      @user1.departments << @d1 << @d3
      @user2 = FactoryGirl.create(:sysadmin_user)
      @user3 = FactoryGirl.create(:admin_user)
      @user3.departments << @d2
      Petition.record_timestamps = false
      @p1 = FactoryGirl.create(:validated_petition, :title => 'King or Queen', :department => @d1, :created_at => 2.days.ago, :updated_at => 25.hours.ago)
      @p2 = FactoryGirl.create(:validated_petition, :title => 'Let us become a republic', :department => @d3, :created_at => 1.day.ago, :updated_at => 5.minutes.ago)
      @p3 = FactoryGirl.create(:pending_petition, :department => @d3)
      @p4 = FactoryGirl.create(:open_petition, :department => @d3)
      @p5 = FactoryGirl.create(:validated_petition)
      Petition.record_timestamps = true
    end

    it "should email out an alert to admin users who belong to departments that have one or more validated petitions" do
      set_up(Chronic.parse("5 July 2011")) # tuesday
      email_no = ActionMailer::Base.deliveries.size
      EmailReminder.admin_email_reminder
      email_no_new = ActionMailer::Base.deliveries.size
      (email_no_new - email_no).should == 1
      email = ActionMailer::Base.deliveries.last
      email.from.should == ["no-reply@example.gov"]
      email.to.should == ["peter@directgov.uk"]
      email.subject.should == 'e-Petitions alert'
    end

    it "should email out details of 1 new petition and two validated petitions on a Tuesday" do
      set_up(Chronic.parse("5 July 2011")) # tuesday
      AdminMailer.should_receive(:admin_email_reminder).with(@user1, [@p2, @p1], 1).and_return(mock('email', :deliver => nil))
      EmailReminder.admin_email_reminder
    end

    it "should email out details of 2 new petitions and two validated petitions on a Tuesday" do
      set_up(Chronic.parse("4 July 2011")) # monday
      AdminMailer.should_receive(:admin_email_reminder).with(@user1, [@p2, @p1], 2).and_return(mock('email', :deliver => nil))
      EmailReminder.admin_email_reminder
    end
  end

  describe "threshold_email_reminders" do
    before :each do
      @user1 = FactoryGirl.create(:threshold_user, :email => 'peter@directgov.uk')
      @user2 = FactoryGirl.create(:threshold_user, :email => 'richard@directgov.uk')
      @p1 = FactoryGirl.create(:open_petition)
      @p1.update_attribute(:signature_count, 11)
      @p2 = FactoryGirl.create(:closed_petition)
      @p2.update_attribute(:signature_count, 10)
      @p3 = FactoryGirl.create(:open_petition)
      @p3.update_attribute(:signature_count, 9)
      @p4 = FactoryGirl.create(:open_petition, :response_required => true)
      @p5 = FactoryGirl.create(:open_petition, :response_required => true, :notified_by_email => true)
      FactoryGirl.create(:system_setting, :key => SystemSetting::THRESHOLD_SIGNATURE_COUNT, :value => "10")
    end

    it "should email out an alert to threshold users for petitions that have reached their threshold or have been marked as requiring a response" do
      email_no = ActionMailer::Base.deliveries.size
      EmailReminder.threshold_email_reminder
      email_no_new = ActionMailer::Base.deliveries.size
      (email_no_new - email_no).should == 1
      email = ActionMailer::Base.deliveries.last
      email.from.should == ["no-reply@example.gov"]
      email.to.should == ["peter@directgov.uk", "richard@directgov.uk"]
      email.subject.should == 'e-Petitions alert'
    end

    it "should email out details of three petitions and set the notified_by_email flag to true" do
      AdminMailer.should_receive(:threshold_email_reminder).with([@user1, @user2], [@p4, @p2, @p1]).and_return(mock('email', :deliver => nil))
      EmailReminder.threshold_email_reminder
      [@p4, @p2, @p1].each do |petition|
        petition.reload
        petition.notified_by_email.should be_true
      end
    end
  end

  describe "special_resend_of_signature_email_validation" do

    let(:beginning_of_september) { Time.parse("2011-09-01 00:00") }
    let(:petition) { FactoryGirl.create(:petition) }
    let!(:validated_signature) { FactoryGirl.create(:signature, :petition => petition, :created_at => beginning_of_september, :updated_at => beginning_of_september) }
    let!(:recent_signature) { FactoryGirl.create(:pending_signature, :petition => petition) }

    before do
      @signatures = []
      3.times do
        @signatures << FactoryGirl.create(:pending_signature, :petition => petition, :created_at => beginning_of_september, :updated_at => beginning_of_september)
      end
    end

    it "sends emails to pending signatures last updated before 14th August 2011" do
      email_count = ActionMailer::Base.deliveries.length
      EmailReminder.special_resend_of_signature_email_validation('2011-09-02')
      (ActionMailer::Base.deliveries.length - email_count).should == 3
    end

    it "updates the time so they aren't sent again" do
      Timecop.freeze do
        EmailReminder.special_resend_of_signature_email_validation('2011-09-02')
        petition.signatures.last.updated_at.should == Time.zone.now
      end
    end

    it "allows customisation of the last updated time" do
      email_count = ActionMailer::Base.deliveries.length
      EmailReminder.special_resend_of_signature_email_validation('2011-03-20')
      (ActionMailer::Base.deliveries.length - email_count).should == 0
    end


    context "syntax error in email" do
      let(:mail) { double }
      before do
        PetitionMailer.stub(:special_resend_of_email_confirmation_for_signer => mail)
        mail.stub(:deliver).and_raise Net::SMTPSyntaxError
      end

      it "continues" do
        expect {
          EmailReminder.special_resend_of_signature_email_validation('2011-09-02')
        }.not_to raise_error
      end

      it "still updates the timestamp" do
        Timecop.freeze do
          EmailReminder.special_resend_of_signature_email_validation('2011-09-02')
          petition.signatures.last.updated_at.should == Time.zone.now
        end
      end
    end
  end
end
