require "rails_helper"

RSpec.describe PetitionMailer, type: :mailer do

  let :creator do
    FactoryGirl.create(:validated_signature, name: "Barry Butler", email: "bazbutler@gmail.com")
  end

  let :petition do
    FactoryGirl.create(:pending_petition,
      creator_signature: creator,
      action: "Allow organic vegetable vans to use red diesel",
      background: "Add vans to permitted users of red diesel",
      additional_details: "To promote organic vegetables"
    )
  end
  let(:pending_signature) { FactoryGirl.create(:pending_signature, :petition => petition) }
  let(:validated_signature) { FactoryGirl.create(:validated_signature, :petition => petition) }
  let(:subject_prefix) { "HM Government & Parliament Petitions" }

  describe "When no signature for an email address exists on a petition" do
    let(:mail) { PetitionMailer.no_signature_for_petition(petition, 'wibble@example.com') }

    it "has an appropriate header for the email" do
      expect(mail.subject).to eq("#{subject_prefix}: a confirmation email has been requested")
    end

    it "informs them there is no signature for that email address on the petition" do
      expect(mail.body.encoded).to match("This email address has not been used to sign this petition")
      expect(mail.body.encoded).to have_css("a", "/petitions/#{petition.id}")
    end
  end

  describe "Signature for an email address has already been confirmed" do
    let(:signature) { FactoryGirl.create(:pending_signature, :petition => petition) }
    let(:mail) { PetitionMailer.email_already_confirmed_for_signature(signature) }

    it "has an appropriate header for the email" do
      expect(mail.subject).to eq("#{subject_prefix}: Signature already confirmed")
    end

    it "informs the user they've already signed the petition" do
      expect(mail.body.encoded).to match("Your signature has already been added to the petition")
    end
  end

  describe "double pending signatures mail" do
    let(:signature_one) { FactoryGirl.create(:pending_signature, :petition => petition) }
    let(:signature_two) { FactoryGirl.create(:pending_signature, :petition => petition) }
    let(:mail) { PetitionMailer.two_pending_signatures(signature_one, signature_two) }

    it "has an appropriate header for the email" do
      expect(mail.subject).to eq("#{subject_prefix}: Signature confirmations")
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
      expect(mail.subject).to eq("#{subject_prefix}: Signature confirmation")
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
    let(:mail) { PetitionMailer.double_signature_confirmation(signature_one, signature_two) }

    it "has an appropriate header for the email" do
      expect(mail.subject).to eq("#{subject_prefix}: Signatures already confirmed")
    end

    it "is addressed to both signees" do
      expect(mail.body.encoded).to match("Dear #{signature_one.name} and #{signature_two.name},")
    end

    it "Informs the signees that their signatures have both been confirmed" do
      expect(mail.body.encoded).to match("signatures have already been added to the petition")
    end
  end

  describe "notifying creator of closing date change" do
    before { petition.publish }
    let(:signature) { FactoryGirl.create(:validated_signature, :petition => petition) }
    let(:mail) { PetitionMailer.notify_creator_of_closing_date_change(signature) }

    it 'has an appropriate subject heading' do
      expect(mail.subject).to eq("#{subject_prefix}: change to your petition closing date")
    end

    it 'is addressed to the creator' do
      expect(mail.body.encoded).to match("Dear #{signature.name}")
    end

    it "informs the creator of the change" do
      expect(mail.body.encoded).to match("Unfortunately we've had to bring forward the closing date")
    end
  end

  describe 'gathering sponsors for petition' do
    subject(:mail) { described_class.gather_sponsors_for_petition(petition) }

    it "has the correct subject" do
      expect(mail.subject).to eq("Parliament petitions - It's time to get sponsors to support your petition")
    end

    it "has the addresses the creator by name" do
      expect(mail.body.encoded).to match(/Dear Barry Butler\,/)
    end

    it "sends it only to the petition creator" do
      expect(mail.to).to eq(%w[bazbutler@gmail.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "includes a link to pass on to potential sponsors to have them support the petition" do
      expect(mail.body.encoded).to match(%r[https://www.example.com/petitions/#{petition.id}/sponsors/#{petition.sponsor_token}])
    end

    it "includes the petition action" do
      expect(mail.body.encoded).to match(%r[Allow organic vegetable vans to use red diesel])
    end

    it "includes the petition background" do
      expect(mail.body.encoded).to match(%r[Add vans to permitted users of red diesel])
    end

    it "includes the petition additional details" do
      expect(mail.body.encoded).to match(%r[To promote organic vegetables])
    end
  end

  describe 'notifying signature of debate outcome' do
    let(:signature) { FactoryGirl.create(:validated_signature, petition: petition, name: 'Laura Palmer', email: 'laura@red-room.example.com') }
    before { FactoryGirl.create(:debate_outcome, petition: petition) }
    subject(:mail) { described_class.notify_signer_of_debate_outcome(petition, signature) }

    it "has the correct subject" do
      expect(mail.subject).to eq("Parliament petitions - The petition '#{petition.action}' has been debated")
    end

    it "addresses the signatory by name" do
      expect(mail.body.encoded).to match(/Dear Laura Palmer\,/)
    end

    it "sends it only to the signatory" do
      expect(mail.to).to eq(%w[laura@red-room.example.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "includes a link to the petition page" do
      expect(mail.body.encoded).to match(%r[https://www.example.com/petitions/#{petition.id}])
    end

    it "includes the petition action" do
      expect(mail.body.encoded).to match(%r[Allow organic vegetable vans to use red diesel])
    end

    it 'includes an unsubscribe link' do
      expect(mail.body.encoded).to match(%r[https://www.example.com/signatures/#{signature.id}/unsubscribe/#{signature.unsubscribe_token}])
    end
  end

  describe 'notifying signature of debate scheduled' do
    let(:petition) { FactoryGirl.create(:open_petition, :scheduled_for_debate, action: "Allow organic vegetable vans to use red diesel") }
    let(:signature) { FactoryGirl.create(:validated_signature, petition: petition, name: 'Laura Palmer', email: 'laura@red-room.example.com') }
    subject(:mail) { described_class.notify_signer_of_debate_scheduled(petition, signature) }

    it "has the correct subject" do
      expect(mail.subject).to eq("HM Government & Parliament Petitions: A debate has been scheduled for the petition '#{petition.action}' you've supported.")
    end

    it "addresses the signatory by name" do
      expect(mail.body.encoded).to match(/Dear Laura Palmer\,/)
    end

    it "sends it only to the signatory" do
      expect(mail.to).to eq(%w[laura@red-room.example.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "includes a link to the petition page" do
      expect(mail.body.encoded).to match(%r[https://www.example.com/petitions/#{petition.id}])
    end

    it 'includes an unsubscribe link' do
      expect(mail.body.encoded).to match(%r[https://www.example.com/signatures/#{signature.id}/unsubscribe/#{signature.unsubscribe_token}])
    end
  end
end
