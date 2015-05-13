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
    it { is_expected.to validate_presence_of(:email).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:petition).with_message(/Needs a petition/) }
    it { is_expected.to allow_value('joe@example.com').for(:email) }
    it { is_expected.not_to allow_value('not an email').for(:email) }

    it 'does not accept petition creator email as a sponsor email ' do
      petition = FactoryGirl.create(:petition)
      sponsor = FactoryGirl.build(:sponsor, petition: petition, email: petition.creator_signature.email)
      expect(sponsor).not_to be_valid
    end
  end

  context 'signature association' do
    let(:sponsor) { FactoryGirl.build(:sponsor) }
    let(:attributes) { {} }

    shared_examples_for 'constructing a signature from a sponsor' do
      it 'is has the same petition as the sponsor' do
        expect(subject.petition).to eq sponsor.petition
      end

      it 'is has the same email address as the sponsor' do
        expect(subject.email).to eq sponsor.email
      end

      it 'is has confirmation of the email address using the same one as the sponsor' do
        expect(subject.email_confirmation).to eq sponsor.email
      end

      it 'does not allow overriding the defaults' do
        attributes[:email] = 'a-brand-new-email@example.com'
        expect(subject.email).not_to eq 'a-brand-new-email@example.com'
      end
    end

    context '#build_signature' do
      subject { sponsor.build_signature(attributes) }
      it_behaves_like 'constructing a signature from a sponsor'
    end

    context '#create_signature' do
      subject { sponsor.create_signature(attributes) }

      it_behaves_like 'constructing a signature from a sponsor'
    end

    context '#create_signature' do
      let(:attributes) { FactoryGirl.attributes_for(:signature) }
      before { sponsor.save! }
      subject { sponsor.create_signature!(attributes) }

      it_behaves_like 'constructing a signature from a sponsor'
    end
  end
end
