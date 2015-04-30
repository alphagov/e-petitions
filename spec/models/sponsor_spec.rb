# == Schema Information
#
# Table name: sponsors
#
#  id               :integer          not null, primary key
#  encrypted_email  :string(255)
#  perishable_token :string(255)
#  petition_id      :integer
#  signature_id     :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

describe Sponsor do

  it "has a valid factory" do
    expect(FactoryGirl.build(:sponsor)).to be_valid
  end

  context "defaults" do
    it "generates perishable token" do
      s = FactoryGirl.create(:sponsor, :perishable_token => nil)
      expect(s.perishable_token).not_to be_nil
    end
  end
  
  context "encryption of email" do
    let(:sponsor) { FactoryGirl.create(:sponsor,
                                       email: "foo@example.net") }
    it "decrypts email correctly" do
      expect(Sponsor.find(sponsor.id).email).to eq("foo@example.net")
    end
    it "is case insensitive" do
      expect(FactoryGirl.build(:sponsor, :email => "FOO@exAmplE.net")
              .encrypted_email).to eq(sponsor.encrypted_email)
    end
    it "returns the sponsor with unencrypted email" do
      expect(Sponsor.for_email("foo@example.net")).to eq([sponsor])
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:petition).with_message(/Needs a petition/) }
    it { is_expected.to allow_value('joe@example.com').for(:email) }
    it { is_expected.not_to allow_value('not an email').for(:email) }
  end
end
