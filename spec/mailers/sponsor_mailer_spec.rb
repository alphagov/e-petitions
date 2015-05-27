require 'rails_helper'

describe SponsorMailer do
  let :creator do
    FactoryGirl.create(:validated_signature, name: "Barry Butler", email: "bazbutler@gmail.com")
  end

  let :petition do
    FactoryGirl.create(:pending_petition,
      creator_signature: creator,
      title: "Allow organic vegetable vans to use red diesel",
      action: "Add vans to permitted users of red diesel",
      description: "To promote organic vegetables"
    )
  end

  let :sponsor do
    FactoryGirl.create(:sponsor, email: "allyadams@outlook.com", petition: petition)
  end

  subject :mail do
    described_class.new_sponsor_email(sponsor)
  end

  describe "#new_sponsor_email" do
    it "has the correct subject" do
      expect(mail.subject).to eq("Parliament petitions - Barry Butler would like your support")
    end

    it "sends it to the sponsor" do
      expect(mail.to).to eq(%w[allyadams@outlook.com])
    end

    it "sends a copy to the creator" do
      expect(mail.cc).to eq(%w[bazbutler@gmail.com])
    end

    it "includes the creator's name in the body" do
      expect(mail.body.encoded).to match(%r[Barry Butler])
    end

    it "includes the petition sponsor url" do
      expect(mail.body.encoded).to match(%r[https://www.example.com/petitions/#{petition.id}/sponsors/#{sponsor.perishable_token}])
    end

    it "includes the petition title" do
      expect(mail.body.encoded).to match(%r[Allow organic vegetable vans to use red diesel])
    end

    it "includes the petition action" do
      expect(mail.body.encoded).to match(%r[Add vans to permitted users of red diesel])
    end

    it "includes the petition subject" do
      expect(mail.body.encoded).to match(%r[To promote organic vegetables])
    end
  end
end
