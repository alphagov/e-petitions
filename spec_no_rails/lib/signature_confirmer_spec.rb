require 'signature_confirmer'

describe SignatureConfirmer do
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
    petition.stub_chain(:signatures, :find_all_by_email).and_return(signatures)
    email.stub(:match => true)
  end

  context "with a malformed email" do
    let(:email) { "malformed address" }
    it "is silently ignored" do
      email.stub(:match => false)

      mailer.should_not_receive(:no_signature_for_petition)
      mailer.should_not_receive(:email_confirmation_for_signer)
      mailer.should_not_receive(:email_already_confirmed_for_signature)
      mailer.should_not_receive(:two_pending_signatures)
      mailer.should_not_receive(:one_pending_one_validated_signature)
      mailer.should_not_receive(:double_signature_confirmation)

      subject.confirm!
    end
  end

  context "will send email" do
    before(:each) { deliverer.should_receive(:deliver) }

    context "email has never signed" do
      it "sends 'no signature for petition'" do
        mailer.should_receive(:no_signature_for_petition).and_return(deliverer)
        subject.confirm!
      end
    end

    context "email has a pending signature" do
      let(:signatures) { [pending_signature] }

      it "sends confirmation email" do
        mailer.should_receive(:email_confirmation_for_signer).and_return(deliverer)
        subject.confirm!
      end
    end

    context "email as a validated signature" do
      let(:signatures) { [validated_signature] }

      it "sends already confirmaed email" do
        mailer.should_receive(:email_already_confirmed_for_signature).and_return(deliverer)
        subject.confirm!
      end
    end

    context "two pending signatures" do
      let(:signatures) { [pending_signature, pending_signature] }

      it "sends one email to both users, containing both confirmation links" do
        mailer.should_receive(:two_pending_signatures).with(*signatures).and_return(deliverer)
        subject.confirm!
      end
    end

    context "one pending, one validated signature" do
      let(:signatures) { [pending_signature, validated_signature] }

      it "sends one email to both users, containing both confirmation links" do
        mailer.should_receive(:one_pending_one_validated_signature).with(*signatures).and_return(deliverer)
        subject.confirm!
      end
    end

    context "two validated signatures" do
      let(:signatures) { [validated_signature, validated_signature] }

      it "sends an email confirming both signatures" do
        mailer.should_receive(:double_signature_confirmation).with(signatures).and_return(deliverer)
        subject.confirm!
      end
    end
  end
end
