require 'signature_confirmer'

RSpec.describe SignatureConfirmer do
  let(:petition) { double }
  let(:email) { "suzie@example.com" }
  let(:mailer) { double }
  let(:deliverer) { double }
  let(:signatures) { [] }
  let(:pending_signature) { double(:pending? => true, :validated? => false) }
  let(:validated_signature) { double(:pending? => false, :validated? => true) }
  let(:regex) { double }

  subject { SignatureConfirmer.new(petition, email, mailer, regex) }

  before do
    allow(petition).to receive_message_chain(:signatures, :for_email).and_return(signatures)
    allow(email).to receive_messages(:match => true)
  end

  context "with a malformed email" do
    let(:email) { "malformed address" }
    it "is silently ignored" do
      allow(email).to receive_messages(:match => false)

      expect(mailer).not_to receive(:no_signature_for_petition)
      expect(mailer).not_to receive(:email_confirmation_for_signer)
      expect(mailer).not_to receive(:email_already_confirmed_for_signature)
      expect(mailer).not_to receive(:two_pending_signatures)
      expect(mailer).not_to receive(:one_pending_one_validated_signature)
      expect(mailer).not_to receive(:double_signature_confirmation)

      subject.confirm!
    end
  end

  context "will send email" do
    before(:each) { expect(deliverer).to receive(:deliver_now) }

    context "email has never signed" do
      it "sends 'no signature for petition'" do
        expect(mailer).to receive(:no_signature_for_petition).and_return(deliverer)
        subject.confirm!
      end
    end

    context "email has a pending signature" do
      let(:signatures) { [pending_signature] }

      it "sends confirmation email" do
        expect(mailer).to receive(:email_confirmation_for_signer).and_return(deliverer)
        subject.confirm!
      end
    end

    context "email as a validated signature" do
      let(:signatures) { [validated_signature] }

      it "sends already confirmaed email" do
        expect(mailer).to receive(:email_already_confirmed_for_signature).and_return(deliverer)
        subject.confirm!
      end
    end

    context "two pending signatures" do
      let(:signatures) { [pending_signature, pending_signature] }

      it "sends one email to both users, containing both confirmation links" do
        expect(mailer).to receive(:two_pending_signatures).with(*signatures).and_return(deliverer)
        subject.confirm!
      end
    end

    context "one pending, one validated signature" do
      let(:signatures) { [pending_signature, validated_signature] }

      it "sends one email to both users, containing both confirmation links" do
        expect(mailer).to receive(:one_pending_one_validated_signature).with(*signatures).and_return(deliverer)
        subject.confirm!
      end
    end

    context "two validated signatures" do
      let(:signatures) { [validated_signature, validated_signature] }

      it "sends an email confirming both signatures" do
        expect(mailer).to receive(:double_signature_confirmation).with(signatures).and_return(deliverer)
        subject.confirm!
      end
    end
  end
end
