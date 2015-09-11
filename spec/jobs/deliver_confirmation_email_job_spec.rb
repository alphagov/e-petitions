require 'rails_helper'

RSpec.describe DeliverConfirmationEmailJob, type: :job do
  let(:petition) { FactoryGirl.create(:responded_petition) }
  let(:signature) { FactoryGirl.create(:pending_signature, petition: petition) }
  let(:fake_mail) { double("Mail", deliver_now: true) }

  before do
    allow(PetitionMailer).to receive(:email_confirmation_for_signer).and_return fake_mail
  end

  it { is_expected.to be_kind_of(ActiveJob::Base) }

  it "uses the deliver_confirmation_email queue" do
    expect(subject.queue_name).to eq("deliver_confirmation_email")
  end

  describe "#perform" do
    it "builds the correct mail" do
      expect(PetitionMailer).to receive(:email_confirmation_for_signer).with(signature).and_return fake_mail
      subject.perform signature
    end

    it "delivers the email" do
      expect(fake_mail).to receive(:deliver_now)
      subject.perform signature
    end
  end
end
