require 'rails_helper'

RSpec.describe SponsorMailer, type: :mailer do
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
      expect(mail).to have_body_text(%r[https://petition.parliament.uk/signatures/#{sponsor.signature.id}/verify/#{sponsor.signature.perishable_token}])
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
end
