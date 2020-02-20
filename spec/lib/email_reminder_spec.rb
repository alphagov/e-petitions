require 'rails_helper'

RSpec.describe EmailReminder do
  describe "special_resend_of_signature_email_validation" do

    let(:beginning_of_september) { Time.parse("2011-09-01 00:00") }
    let(:petition) { FactoryBot.create(:petition) }
    let!(:validated_signature) { FactoryBot.create(:signature, :petition => petition, :created_at => beginning_of_september, :updated_at => beginning_of_september) }
    let!(:recent_signature) { FactoryBot.create(:pending_signature, :petition => petition) }

    before do
      @signatures = []
      3.times do
        @signatures << FactoryBot.create(:pending_signature, :petition => petition, :created_at => beginning_of_september, :updated_at => beginning_of_september)
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
