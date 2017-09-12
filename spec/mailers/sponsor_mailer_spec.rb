require 'rails_helper'

RSpec.describe SponsorMailer, type: :mailer do
  let :creator do
    FactoryGirl.create(:validated_signature, name: "Barry Butler", email: "bazbutler@gmail.com")
  end

  let :petition do
    FactoryGirl.create(:pending_petition,
      creator: creator,
      action: "Allow organic vegetable vans to use red diesel",
      background: "Add vans to permitted users of red diesel",
      additional_details: "To promote organic vegetables"
    )
  end

  let :sponsor do
    FactoryGirl.create(:sponsor, :pending, email: 'allyadams@outlook.com', petition: petition)
  end

  describe "#petition_and_email_confirmation_for_sponsor" do
    subject(:mail) { described_class.petition_and_email_confirmation_for_sponsor(sponsor) }

    it "has the correct subject" do
      expect(mail.subject).to eq("Please confirm your email address")
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
    subject(:mail) { described_class.sponsor_signed_email_below_threshold(petition, sponsor) }

    context "when the number of supporters is 1" do
      before do
        allow(petition).to receive_message_chain(:sponsors, :validated, :count).and_return(1)
      end

      it "pluralizes supporters correctly" do
        expect(mail).to have_body_text(%r[You have 1 supporter so far])
      end
    end

    context "when the number of supporters is more than 1" do
      before do
        allow(petition).to receive_message_chain(:sponsors, :validated, :count).and_return(2)
      end

      it "pluralizes supporters correctly" do
        expect(mail).to have_body_text(%r[You have 2 supporters so far])
      end
    end
  end
end
