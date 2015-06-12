require 'rails_helper'

describe EmailReminder do
  describe "threshold_email_reminders" do
    before :each do
      @user1 = FactoryGirl.create(:moderator_user, :email => 'peter@directgov.uk')
      @user2 = FactoryGirl.create(:moderator_user, :email => 'richard@directgov.uk')
      @p1 = FactoryGirl.create(:open_petition)
      @p1.update_attribute(:signature_count, 11)
      @p2 = FactoryGirl.create(:closed_petition)
      @p2.update_attribute(:signature_count, 10)
      @p3 = FactoryGirl.create(:open_petition)
      @p3.update_attribute(:signature_count, 9)
      @p4 = FactoryGirl.create(:open_petition, :response_required => true)
      @p5 = FactoryGirl.create(:open_petition, :response_required => true, :notified_by_email => true)

      allow(Site).to receive(:threshold_for_debate).and_return(10)
    end

    it "should email out an alert to moderator users for petitions that have reached their threshold or have been marked as requiring a response" do
      email_no = ActionMailer::Base.deliveries.size
      EmailReminder.threshold_email_reminder
      email_no_new = ActionMailer::Base.deliveries.size
      expect(email_no_new - email_no).to eq(1)
      email = ActionMailer::Base.deliveries.last
      expect(email.from).to eq(["no-reply@petition.parliament.uk"])
      expect(email.to).to match_array(["peter@directgov.uk", "richard@directgov.uk"])
      expect(email.subject).to eq('e-Petitions alert')
    end

    it "should email out details of three petitions and set the notified_by_email flag to true" do
      expect(AdminMailer).to receive(:threshold_email_reminder).with([@user1, @user2], [@p4, @p2, @p1]).and_return(double('email', :deliver_now => nil))
      EmailReminder.threshold_email_reminder
      [@p4, @p2, @p1].each do |petition|
        petition.reload
        expect(petition.notified_by_email).to be_truthy
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
      expect(ActionMailer::Base.deliveries.length - email_count).to eq(3)
    end

    it "updates the time so they aren't sent again" do
      EmailReminder.special_resend_of_signature_email_validation('2011-09-02')
      expect(petition.signatures.last.updated_at).to be_within(1.second).of(Time.current)
    end

    it "allows customisation of the last updated time" do
      email_count = ActionMailer::Base.deliveries.length
      EmailReminder.special_resend_of_signature_email_validation('2011-03-20')
      expect(ActionMailer::Base.deliveries.length - email_count).to eq(0)
    end


    context "syntax error in email" do
      let(:mail) { double }
      before do
        allow(PetitionMailer).to receive_messages(:special_resend_of_email_confirmation_for_signer => mail)
        allow(mail).to receive(:deliver_now).and_raise Net::SMTPSyntaxError
      end

      it "continues" do
        expect {
          EmailReminder.special_resend_of_signature_email_validation('2011-09-02')
        }.not_to raise_error
      end

      it "still updates the timestamp" do
        EmailReminder.special_resend_of_signature_email_validation('2011-09-02')
        expect(petition.signatures.last.updated_at).to be_within(1.second).of(Time.current)
      end
    end
  end
end
