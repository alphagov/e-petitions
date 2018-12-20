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

  describe "#sponsor_signed_email_on_threshold" do
    subject(:mail) { described_class.sponsor_signed_email_on_threshold(petition, sponsor) }

    before do
      allow(petition).to receive_message_chain(:sponsors, :validated, :count).and_return(5)
    end

    shared_examples_for "a sponsor signed on threshold email" do
      it "has the correct subject" do
        expect(mail.subject).to eq("We’re checking your petition")
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
        expect(mail).to have_body_text(%r[Ally Adams])
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
        expect(mail).to have_body_text(%r[5 people have supported your petition so far])
      end

      it "tells the creator that the petition is being checked" do
        expect(mail).to have_body_text(%r[We’re checking your petition to make sure it meets the petition standards])
      end
    end

    context "before the Christmas period" do
      around do |example|
        travel_to("2017-12-21") { example.run }
      end

      it_behaves_like "a sponsor signed on threshold email"

      it "doesn't include the moderation delay message" do
        expect(mail).not_to have_body_text(%r[over the Christmas period it will take us a little longer than usual])
      end
    end

    context "during the Christmas period" do
      around do |example|
        travel_to("2017-12-26") { example.run }
      end

      it_behaves_like "a sponsor signed on threshold email"

      it "includes the moderation delay message" do
        expect(mail).to have_body_text(%r[over the Christmas period it will take us a little longer than usual])
      end
    end

    context "after the Christmas period" do
      around do |example|
        travel_to("2018-01-05") { example.run }
      end

      it_behaves_like "a sponsor signed on threshold email"

      it "doesn't include the moderation delay message" do
        expect(mail).not_to have_body_text(%r[over the Christmas period it will take us a little longer than usual])
      end
    end

    context "before the Easter period" do
      around do |example|
        travel_to("2018-03-29") { example.run }
      end

      it_behaves_like "a sponsor signed on threshold email"

      it "doesn't include the moderation delay message" do
        expect(mail).not_to have_body_text(%r[over the Easter period it will take us a little longer than usual])
      end
    end

    context "during the Easter period" do
      around do |example|
        travel_to("2018-04-01") { example.run }
      end

      it_behaves_like "a sponsor signed on threshold email"

      it "includes the moderation delay message" do
        expect(mail).to have_body_text(%r[over the Easter period it will take us a little longer than usual])
      end
    end

    context "after the Easter period" do
      around do |example|
        travel_to("2018-04-10") { example.run }
      end

      it_behaves_like "a sponsor signed on threshold email"

      it "doesn't include the moderation delay message" do
        expect(mail).not_to have_body_text(%r[over the Easter period it will take us a little longer than usual])
      end
    end
  end
end
