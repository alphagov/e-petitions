require 'rails_helper'

RSpec.describe SponsorMailer, type: :mailer do
  let :creator do
    FactoryBot.create(:validated_signature, name: "Barry Butler", email: "bazbutler@gmail.com", creator: true)
  end

  let :petition do
    FactoryBot.create(:pending_petition,
      creator: creator,
      action: "Allow organic vegetable vans to use red diesel",
      background: "Add vans to permitted users of red diesel",
      additional_details: "To promote organic vegetables"
    )
  end

  let :sponsor do
    FactoryBot.create(:sponsor, :pending, name: "Ally Adams", email: 'allyadams@outlook.com', petition: petition)
  end

  describe "#petition_and_email_confirmation_for_sponsor" do
    subject(:mail) { described_class.petition_and_email_confirmation_for_sponsor(sponsor) }

    it "has the correct subject" do
      expect(mail.subject).to eq("Sign to support: “#{petition.action}”")
    end

    it "sends it only to the sponsor" do
      expect(mail.to).to eq(%w[allyadams@outlook.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "includes the creator's name in the body" do
      expect(mail).to have_body_text(%r[Barry Butler])
    end

    it "includes the verification url for the sponsor's signature" do
      expect(mail).to have_body_text(%r[https://petition.parliament.uk/sponsors/#{sponsor.id}/verify\?token=#{sponsor.perishable_token}])
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

  describe "#sponsor_signed_email_below_threshold" do
    subject(:mail) { described_class.sponsor_signed_email_below_threshold(sponsor) }

    context "when the number of supporters is 1" do
      let(:sponsors) { double }

      before do
        validated = -> (&block) {
          expect(block).to eq(:validated?.to_proc)
        }

        allow(petition).to receive(:sponsors).and_return(sponsors)
        allow(sponsors).to receive(:select, &validated).and_return(sponsors)
        allow(sponsors).to receive(:size).and_return(1)
      end

      it "pluralizes supporters correctly" do
        expect(mail).to have_body_text(%r[You have 1 supporter so far])
      end
    end

    context "when the number of supporters is more than 1" do
      let(:sponsors) { double }

      before do
        validated = -> (&block) {
          expect(block).to eq(:validated?.to_proc)
        }

        allow(petition).to receive(:sponsors).and_return(sponsors)
        allow(sponsors).to receive(:select, &validated).and_return(sponsors)
        allow(sponsors).to receive(:size).and_return(2)
      end

      it "pluralizes supporters correctly" do
        expect(mail).to have_body_text(%r[You have 2 supporters so far])
      end
    end
  end

  describe "#sponsor_signed_email_on_threshold" do
    let(:petition_scope) { double(Petition) }
    let(:moderation_queue) { 499 }

    before do
      allow(Petition).to receive(:in_moderation).and_return(petition_scope)
      allow(petition_scope).to receive(:count).and_return(moderation_queue)
    end

    subject(:mail) { described_class.sponsor_signed_email_on_threshold(sponsor) }

    before do
      allow(petition).to receive_message_chain(:sponsors, :validated, :count).and_return(5)
    end

    shared_examples_for "a sponsor signed on threshold email" do
      it "has the correct subject" do
        expect(mail.subject).to eq("Your petition has five supporters: “#{petition.action}”")
      end

      it "sends it only to the creator" do
        expect(mail.to).to eq(%w[bazbutler@gmail.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "includes the creator's name in the body" do
        expect(mail).to have_body_text(%r[Barry Butler])
      end

      it "includes the sponsor's name in the body" do
        expect(mail).to have_body_text(%r[Someone supported your petition])
      end

      it "includes the petition action" do
        expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
      end

      it "doesn't include the petition background" do
        expect(mail).not_to have_body_text(%r[Add vans to permitted users of red diesel])
      end

      it "doesn't include the petition additional details" do
        expect(mail).not_to have_body_text(%r[To promote organic vegetables])
      end

      it "includes the sponsor count" do
        expect(mail).to have_body_text(%r[5 people have supported your petition])
      end

      it "tells the creator that the petition is being checked" do
        expect(mail).to have_body_text(%r[We’re checking it to make sure it meets the petition standards])
      end

      context "when there is a moderation delay" do
        let(:moderation_queue) { 500 }

        it "includes information about delayed moderation" do
          expect(mail).to have_body_text(%r[We have a very large number of petitions to check])
        end
      end
    end
  end

  describe "skipping anonymized signatures" do
    context "when sending an email to the creator" do
      let(:mail) do
        described_class.sponsor_signed_email_below_threshold(sponsor)
      end

      context "and the signature is not anonymized" do
        it "will deliver the email" do
          expect(mail.perform_deliveries).to eq(true)
        end
      end

      context "and the signature is anonymized" do
        let :creator do
          FactoryBot.create(:validated_signature, creator: true, created_at: 13.months.ago, anonymized_at: 1.month.ago)
        end

        it "will not deliver the email" do
          expect(mail.perform_deliveries).to eq(false)
        end
      end
    end

    context "when sending an email to the sponsor" do
      let(:mail) do
        described_class.petition_and_email_confirmation_for_sponsor(sponsor)
      end

      context "and the signature is not anonymized" do
        it "will deliver the email" do
          expect(mail.perform_deliveries).to eq(true)
        end
      end

      context "and the signature is anonymized" do
        let :sponsor do
          FactoryBot.create(:sponsor, :pending, petition: petition, created_at: 13.months.ago, anonymized_at: 1.month.ago)
        end

        it "will not deliver the email" do
          expect(mail.perform_deliveries).to eq(false)
        end
      end
    end
  end
end
