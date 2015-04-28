require "rails_helper"

describe PetitionMailer do

  let(:petition) { FactoryGirl.create(:open_petition) }
  let(:pending_signature) { FactoryGirl.create(:pending_signature, :petition => petition) }
  let(:validated_signature) { FactoryGirl.create(:validated_signature, :petition => petition) }

  describe "When no signature for an email address exists on a petition" do
    let(:mail) { PetitionMailer.no_signature_for_petition(petition, 'wibble@example.com') }

    it "has an appropriate header for the email" do
      expect(mail.subject).to eq("HM Government e-petitions: a confirmation email has been requested")
    end

    it "informs them there is no signature for that email address on the petition" do
      expect(mail.body.encoded).to match("This email address has not been used to sign this e-petition")
      expect(mail.body.encoded).to have_css("a", "/petitions/#{petition.id}")
    end
  end

  describe "Signature for an email address has already been confirmed" do
    let(:signature) { FactoryGirl.create(:pending_signature, :petition => petition) }
    let(:mail) { PetitionMailer.email_already_confirmed_for_signature(signature) }

    it "has an appropriate header for the email" do
      expect(mail.subject).to eq("HM Government e-petitions: Signature already confirmed")
    end

    it "informs the use they've already signed the petition" do
      expect(mail.body.encoded).to match("Your signature has already been added to the e-petition")
    end
  end

  describe "double pending signatures mail" do
    let(:signature_one) { FactoryGirl.create(:pending_signature, :petition => petition) }
    let(:signature_two) { FactoryGirl.create(:pending_signature, :petition => petition) }
    let(:mail) { PetitionMailer.two_pending_signatures(signature_one, signature_two) }

    it "has an appropriate header for the email" do
      expect(mail.subject).to eq("HM Government e-petitions: Signature confirmations")
    end

    it "is addressed to both signees" do
      expect(mail.body.encoded).to match("Dear #{signature_one.name} and #{signature_two.name},")
    end

    it "provides links to confirm both signatures" do
      expect(mail.body.encoded).to have_css("a", :text => "/signatures/#{signature_one.id}/verify/#{signature_one.perishable_token}")
      expect(mail.body.encoded).to have_css("a", :text => "/signatures/#{signature_two.id}/verify/#{signature_two.perishable_token}")
    end
  end

  describe "one pending and one validated signature mail" do
    let(:pending_signature) { FactoryGirl.create(:pending_signature, :petition => petition) }
    let(:validated_signature) { FactoryGirl.create(:validated_signature, :petition => petition) }
    let(:mail) { PetitionMailer.one_pending_one_validated_signature(pending_signature, validated_signature) }

    it "has an appropriate header for the email" do
      expect(mail.subject).to eq("HM Government e-petitions: Signature confirmation")
    end

    it "is addressed to both signees" do
      expect(mail.body.encoded).to match("Dear #{pending_signature.name} and #{validated_signature.name},")
    end

    it "provides a link to confirm the pending signature" do
      expect(mail.body.encoded).to have_css("a", :text => "/signatures/#{pending_signature.id}/verify/#{pending_signature.perishable_token}")
    end

    it "awknowledges one petition has been validated" do
      expect(mail.body.encoded).to match("Signature for #{validated_signature.name} has already been confirmed")
    end
  end

  describe "both signatures are validated" do
    let(:signature_one) { FactoryGirl.create(:validated_signature, :petition => petition) }
    let(:signature_two) { FactoryGirl.create(:validated_signature, :petition => petition) }
    let(:mail) { PetitionMailer.double_signature_confirmation([signature_one, signature_two]) }

    it "has an appropriate header for the email" do
      expect(mail.subject).to eq("HM Government e-petitions: Signatures already confirmed")
    end

    it "is addressed to both signees" do
      expect(mail.body.encoded).to match("Dear #{signature_one.name} and #{signature_two.name},")
    end

    it "Informs the signees that their signatures have both been confirmed" do
      expect(mail.body.encoded).to match("signatures have already been added to the e-petition")
    end
  end

  describe "notifying creator of closing date change" do
    let(:signature) { FactoryGirl.create(:validated_signature, :petition => petition) }
    let(:mail) { PetitionMailer.notify_creator_of_closing_date_change(signature) }

    it 'has an appropriate subject heading' do
      expect(mail.subject).to eq("HM Government e-petitions: change to your e-petition closing date")
    end

    it 'is addressed to the creator' do
      expect(mail.body.encoded).to match("Dear #{signature.name}")
    end

    it "informs the creator of the change" do
      expect(mail.body.encoded).to match("Unfortunately we've had to bring forward the closing date")
    end
  end

end
