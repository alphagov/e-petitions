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

  let(:pending_signature) { FactoryGirl.create(:pending_signature, petition: petition) }
  let(:validated_signature) { FactoryGirl.create(:validated_signature, petition: petition) }
  let(:subject_prefix) { "HM Government & Parliament Petitions" }

  describe "notifying creator of publication" do
    let(:mail) { PetitionMailer.notify_creator_that_petition_is_published(creator) }

    before do
      petition.publish
    end

    it "is sent to the right address" do
      expect(mail.to).to eq(%w[bazbutler@gmail.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "has an appropriate subject heading" do
      expect(mail).to have_subject('We published your petition "Allow organic vegetable vans to use red diesel"')
    end

    it "is addressed to the creator" do
      expect(mail).to have_body_text("Dear Barry Butler,")
    end

    it "informs the creator of the publication" do
      expect(mail).to have_body_text("We published the petition you created")
    end
  end

  describe "notifying sponsor of publication" do
    let(:mail) { PetitionMailer.notify_sponsor_that_petition_is_published(sponsor) }
    let(:sponsor) do
      FactoryGirl.create(:validated_signature,
        name: "Laura Palmer",
        email: "laura@red-room.example.com",
        petition: petition
      )
    end

    before do
      petition.publish
    end

    it "is sent to the right address" do
      expect(mail.to).to eq(%w[laura@red-room.example.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "has an appropriate subject heading" do
      expect(mail).to have_subject('We published the petition "Allow organic vegetable vans to use red diesel" that you supported')
    end

    it "is addressed to the sponsor" do
      expect(mail).to have_body_text("Dear Laura Palmer,")
    end

    it "informs the sponsor of the publication" do
      expect(mail).to have_body_text("We published the petition you supported")
    end
  end

  describe "notifying creator of closing date change" do
    let(:mail) { PetitionMailer.notify_creator_of_closing_date_change(creator) }

    before do
      petition.publish
    end

    it "is sent to the right address" do
      expect(mail.to).to eq(%w[bazbutler@gmail.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "has an appropriate subject heading" do
      expect(mail).to have_subject("We’re closing your petition early")
    end

    it "is addressed to the creator" do
      expect(mail).to have_body_text("Dear Barry Butler,")
    end

    it "informs the creator of the change" do
      expect(mail).to have_body_text("Unfortunately we’re closing all petitions")
    end
  end

  describe "gathering sponsors for petition" do
    subject(:mail) { described_class.gather_sponsors_for_petition(petition) }

    it "has the correct subject" do
      expect(mail).to have_subject(%{Action required: Petition "Allow organic vegetable vans to use red diesel"})
    end

    it "has the addresses the creator by name" do
      expect(mail).to have_body_text("Dear Barry Butler,")
    end

    it "sends it only to the petition creator" do
      expect(mail.to).to eq(%w[bazbutler@gmail.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "includes a link to pass on to potential sponsors to have them support the petition" do
      expect(mail).to have_body_text(%r[https://petition.parliament.uk/petitions/#{petition.id}/sponsors/#{petition.sponsor_token}])
    end

    it "includes the petition action" do
      expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
    end

    it "includes the petition background" do
      expect(mail).to have_body_text(%r[Add vans to permitted users of red diesel])
    end

    it "includes the petition additional details" do
      expect(mail).to have_body_text(%r[To promote organic vegetables])
    end
  end

  describe "notifying signature of debate outcome" do
    let(:signature) { FactoryGirl.create(:validated_signature, petition: petition, name: "Laura Palmer", email: "laura@red-room.example.com") }
    before { FactoryGirl.create(:debate_outcome, petition: petition) }
    subject(:mail) { described_class.notify_signer_of_debate_outcome(petition, signature) }

    it "has the correct subject" do
      expect(mail).to have_subject("Parliament debated your petition")
    end

    it "addresses the signatory by name" do
      expect(mail).to have_body_text("Dear Laura Palmer,")
    end

    it "sends it only to the signatory" do
      expect(mail.to).to eq(%w[laura@red-room.example.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "includes a link to the petition page" do
      expect(mail).to have_body_text(%r[https://petition.parliament.uk/petitions/#{petition.id}])
    end

    it "includes the petition action" do
      expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
    end

    it "includes an unsubscribe link" do
      expect(mail).to have_body_text(%r[https://petition.parliament.uk/signatures/#{signature.id}/unsubscribe/#{signature.unsubscribe_token}])
    end
  end

  describe "notifying signature of debate scheduled" do
    let(:petition) { FactoryGirl.create(:open_petition, :scheduled_for_debate, action: "Allow organic vegetable vans to use red diesel") }
    let(:signature) { FactoryGirl.create(:validated_signature, petition: petition, name: "Laura Palmer", email: "laura@red-room.example.com") }
    subject(:mail) { described_class.notify_signer_of_debate_scheduled(petition, signature) }

    it "has the correct subject" do
      expect(mail).to have_subject("Parliament will debate your petition")
    end

    it "addresses the signatory by name" do
      expect(mail).to have_body_text("Dear Laura Palmer,")
    end

    it "sends it only to the signatory" do
      expect(mail.to).to eq(%w[laura@red-room.example.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "includes a link to the petition page" do
      expect(mail).to have_body_text(%r[https://petition.parliament.uk/petitions/#{petition.id}])
    end

    it "includes an unsubscribe link" do
      expect(mail).to have_body_text(%r[https://petition.parliament.uk/signatures/#{signature.id}/unsubscribe/#{signature.unsubscribe_token}])
    end
  end

  describe "emailing a signature" do
    let(:petition) { FactoryGirl.create(:open_petition, :scheduled_for_debate, action: "Allow organic vegetable vans to use red diesel") }
    let(:signature) { FactoryGirl.create(:validated_signature, petition: petition, name: "Laura Palmer", email: "laura@red-room.example.com") }
    let(:email) { FactoryGirl.create(:petition_email, petition: petition, subject: "This is a message from the committee", body: "Message body from the petition committee") }
    subject(:mail) { described_class.email_signer(petition, signature, email) }

    it "has the correct subject" do
      expect(mail).to have_subject("This is a message from the committee")
    end

    it "addresses the signatory by name" do
      expect(mail).to have_body_text("Dear Laura Palmer,")
    end

    it "sends it only to the signatory" do
      expect(mail.to).to eq(%w[laura@red-room.example.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "includes a link to the petition page" do
      expect(mail).to have_body_text(%r[https://petition.parliament.uk/petitions/#{petition.id}])
    end

    it "includes an unsubscribe link" do
      expect(mail).to have_body_text(%r[https://petition.parliament.uk/signatures/#{signature.id}/unsubscribe/#{signature.unsubscribe_token}])
    end

    it "includes the message body" do
      expect(mail).to have_body_text(%r[Message body from the petition committee])
    end
  end
end
