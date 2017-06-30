require "rails_helper"

RSpec.describe Archived::PetitionMailer, type: :mailer do
  let :creator do
    FactoryGirl.create(:archived_signature,
      name: "Barry Butler",
      email: "bazbutler@gmail.com",
      creator: true
    )
  end

  let(:signer) do
    FactoryGirl.create(:archived_signature,
      name: "Laura Palmer",
      email: "laurapalmer@hotmail.com",
      petition: petition
    )
  end

  describe "notifying signature of a government response" do
    let :petition do
      FactoryGirl.create(:archived_petition, :response,
        action: "Allow organic vegetable vans to use red diesel",
        background: "Add vans to permitted users of red diesel",
        additional_details: "To promote organic vegetables",
        response_summary: "Sounds like a good idea",
        response_details: "We’ll get right on that",
        signature_count: signature_count
      )
    end

    let(:signature_count) { 15000 }

    shared_examples_for "a government response email" do
      it "includes a link to the petition page" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
      end

      it "includes the petition action" do
        expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
      end

      it "includes an unsubscribe link" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
      end

      it "has a List-Unsubscribe header" do
        expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
      end

      it "has the correct subject" do
        expect(mail).to have_subject("Government responded to “Allow organic vegetable vans to use red diesel”")
      end

      it "has response summary in the body" do
        expect(mail).to have_body_text("Sounds like a good idea")
      end

      it "has response details in the body" do
        expect(mail).to have_body_text("We’ll get right on that")
      end

      it "includes a link to read the response online" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}\?reveal_response=yes])
      end

      context "when the signature count is less than the debate threshold" do
        let(:signature_count) { 12345 }

        it "includes a message about the committee's response" do
          expect(mail).to have_body_text("The Petitions Committee will take a look at this petition and its response.")
          expect(mail).to have_body_text("They can press the government for action and gather evidence.")
          expect(mail).to have_body_text("If this petition reaches 100,000 signatures, the Committee will consider it for a debate.")
        end
      end

      context "when the signature count is more than the debate threshold" do
        let(:signature_count) { 123456 }

        it "includes a message about the committee's response" do
          expect(mail).to have_body_text("This petition has over 100,000 signatures.")
          expect(mail).to have_body_text("The Petitions Committee will consider it for a debate.")
          expect(mail).to have_body_text("They can also gather further evidence and press the government for action.")
        end
      end
    end

    context "when the signature is the creator" do
      let(:signature) { creator }
      subject(:mail) { described_class.notify_creator_of_threshold_response(petition, signature) }

      it_behaves_like "a government response email"

      it "sends it only to the creator" do
        expect(mail.to).to eq(%w[bazbutler@gmail.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear Barry Butler,")
      end

      it "has the message in the body" do
        expect(mail).to have_body_text("The Government has responded to your petition")
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { signer }
      subject(:mail) { described_class.notify_signer_of_threshold_response(petition, signature) }

      it_behaves_like "a government response email"

      it "sends it only to the signer" do
        expect(mail.to).to eq(%w[laurapalmer@hotmail.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear Laura Palmer,")
      end

      it "has the message in the body" do
        expect(mail).to have_body_text("The Government has responded to the petition you signed")
      end
    end
  end

  describe "notifying signature of a debate being scheduled" do
    let :petition do
      FactoryGirl.create(:archived_petition, :scheduled_for_debate,
        action: "Allow organic vegetable vans to use red diesel",
        background: "Add vans to permitted users of red diesel",
        additional_details: "To promote organic vegetables",
        scheduled_debate_date: "2017-09-12"
      )
    end

    shared_examples_for "a debate scheduled email" do
      it "includes a link to the petition page" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/petitions/#{petition.id}])
      end

      it "includes the petition action" do
        expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
      end

      it "includes an unsubscribe link" do
        expect(mail).to have_body_text(%r[https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
      end

      it "has a List-Unsubscribe header" do
        expect(mail).to have_header("List-Unsubscribe", "<https://petition.parliament.uk/archived/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
      end

      it "has the correct subject" do
        expect(mail).to have_subject("Parliament will debate “Allow organic vegetable vans to use red diesel”")
      end

      it "has the scheduled debate date in the body" do
        expect(mail).to have_body_text("12 September 2017")
      end
    end

    context "when the signature is the creator" do
      let(:signature) { creator }
      subject(:mail) { described_class.notify_creator_of_debate_scheduled(petition, signature) }

      it_behaves_like "a debate scheduled email"

      it "sends it only to the creator" do
        expect(mail.to).to eq(%w[bazbutler@gmail.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear Barry Butler,")
      end

      it "has the message in the body" do
        expect(mail).to have_body_text("Parliament is going to debate your petition")
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { signer }
      subject(:mail) { described_class.notify_signer_of_debate_scheduled(petition, signature) }

      it_behaves_like "a debate scheduled email"

      it "sends it only to the signer" do
        expect(mail.to).to eq(%w[laurapalmer@hotmail.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear Laura Palmer,")
      end

      it "has the message in the body" do
        expect(mail).to have_body_text("Parliament is going to debate the petition you signed")
      end
    end
  end
end
