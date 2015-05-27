# == Schema Information
#
# Table name: signatures
#
#  id               :integer(4)      not null, primary key
#  name             :string(255)     not null
#  state            :string(10)      default("pending"), not null
#  perishable_token :string(255)
#  postcode         :string(255)
#  country          :string(255)
#  ip_address       :string(20)
#  petition_id      :integer(4)
#  created_at       :datetime
#  updated_at       :datetime
#  notify_by_email  :boolean(1)      default(FALSE)
#  last_emailed_at  :datetime
#  encrypted_email  :string(255)
#

require 'rails_helper'
require 'webmock/rspec'

describe Signature do
  it "should have a valid factory" do
    expect(FactoryGirl.build(:signature)).to be_valid
  end

  context "defaults" do
    it "state should default to pending" do
      s = Signature.new
      expect(s.state).to eq("pending")
    end

    it "generates perishable token" do
      s = FactoryGirl.create(:signature, :perishable_token => nil)
      expect(s.perishable_token).not_to be_nil
    end

    it "should set notify_by_email to truthy" do
      s = Signature.new
      expect(s.notify_by_email).to be_truthy
    end

    it "generates unsubscription token" do
      s = FactoryGirl.create(:signature, :unsubscribe_token=> nil)
      expect(s.unsubscribe_token).not_to be_nil
    end

  end

  context "encryption of email" do
    let(:signature) { FactoryGirl.create(:signature, :email => "foo@example.net") }
    it "transparently alters the email" do
      expect(Signature.find(signature.id).email).to eq("foo@example.net")
    end

    it "take no notice of the case" do
      expect(FactoryGirl.build(:signature, :email => "FOO@exAmplE.net").encrypted_email).to eq(signature.encrypted_email)
    end

    it "for_email takes into account the encrypted email" do
      expect(Signature.for_email("foo@example.net")).to eq([signature])
    end
  end

  RSpec::Matchers.define :have_valid do |field|
    match do |actual|
      expect(actual.errors_on(field)).to be_blank
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:name).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:email).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:country).with_message(/must be completed/) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }

    it "should validate format of email" do
      s = FactoryGirl.build(:signature, :email => 'joe@example.com')
      expect(s).to have_valid(:email)
    end

    it "should not allow invalid email" do
      s = FactoryGirl.build(:signature, :email => 'not an email')
      expect(s).not_to have_valid(:email)
    end

    describe "uniqueness of email" do
      before do
        FactoryGirl.create(:signature, :name => "Suzy Signer",
                       :petition_id => 1, :postcode => "sw1a 1aa",
                       :email => 'foo@example.com')
      end

      it "allows a second email to be used" do
        s = FactoryGirl.build(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        expect(s).to have_valid(:email)
      end

      it "does not allow a third email to be used" do
        FactoryGirl.create(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        s = FactoryGirl.build(:signature, :name => "Sarah Signer",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        expect(s).not_to have_valid(:email)
      end

      it "does not allow the second email if the name is the same" do
        s = FactoryGirl.build(:signature, :name => "Suzy Signer",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        expect(s).not_to have_valid(:email)
      end

      it "ignores extra whitespace on name" do
        s = FactoryGirl.build(:signature, :name => "Suzy Signer ",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        expect(s).not_to have_valid(:email)
        s = FactoryGirl.build(:signature, :name => " Suzy Signer",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        expect(s).not_to have_valid(:email)
      end

      it "only allows the second email if the postcode is the same" do
        s = FactoryGirl.build(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a 1ab',
                          :email => 'foo@example.com')
        expect(s).not_to have_valid(:email)
      end

      it "ignores the space on the postcode check" do
        s = FactoryGirl.build(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a1aa',
                          :email => 'foo@example.com')
        expect(s).to have_valid(:email)
        s = FactoryGirl.build(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a1ab',
                          :email => 'foo@example.com')
        expect(s).not_to have_valid(:email)
      end

      it "does a case insensitive postcode check" do
        s = FactoryGirl.build(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a 1Aa',
                          :email => 'foo@example.com')
        expect(s).to have_valid(:email)
      end

      it "is case insensitive about the subsequent validations" do
        s = FactoryGirl.create(:signature, :petition_id => 1, :postcode => 'sw1a 1aa',
                      :email => 'fOo@Example.com')
        expect(s).to have_valid(:email)
        s = FactoryGirl.build(:signature, :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'FOO@Example.com')
        expect(s).not_to have_valid(:email)
      end

      it "is scoped to petition" do
        s = FactoryGirl.build(:signature, :petition_id => 2, :email => 'foo@example.com')
        expect(s).to have_valid(:email)
      end
    end

    it "should not allow blank or unknown state" do
      s = FactoryGirl.build(:signature, :state => '')
      expect(s).not_to have_valid(:state)
      s.state = 'unknown'
      expect(s).not_to have_valid(:state)
    end

    it "should allow known states" do
      s = FactoryGirl.build(:signature)
      %w(pending validated ).each do |state|
        s.state = state
        expect(s).to have_valid(:state)
      end
    end

    describe "postcode" do
      it "requires a postcode for a UK address" do
        expect(FactoryGirl.build(:signature, :postcode => 'SW1A 1AA')).to be_valid
        expect(FactoryGirl.build(:signature, :postcode => '')).not_to be_valid
      end

      it "does not require a postcode for non-UK addresses" do
        expect(FactoryGirl.build(:signature, :country => "United Kingdom", :postcode => '')).not_to be_valid
        expect(FactoryGirl.build(:signature, :country => "United States", :postcode => '')).to be_valid
      end

      it "checks the format of postcode" do
        s = FactoryGirl.build(:signature, :postcode => 'SW1A 1AA')
        expect(s).to have_valid(:postcode)
      end
      it "ignores lack of spaces in postcode" do
        s = FactoryGirl.build(:signature, :postcode => 'SW1A1AA')
        expect(s).to have_valid(:postcode)
      end
      it "does not require upper case letters in postcode" do
        s = FactoryGirl.build(:signature, :postcode => 'sw1a 1aa')
        expect(s).to have_valid(:postcode)
      end
      it "recognises special postcodes" do
        expect(FactoryGirl.build(:signature, :postcode => 'BFPO 1234')).to have_valid(:postcode)
        expect(FactoryGirl.build(:signature, :postcode => 'XM4 5HQ')).to have_valid(:postcode)
        expect(FactoryGirl.build(:signature, :postcode => 'GIR 0AA')).to have_valid(:postcode)
      end

      it "does not allow unrecognised postcodes" do
        s = FactoryGirl.build(:signature, :postcode => '90210')
        expect(s).not_to have_valid(:postcode)
      end
    end

    describe "post district" do
      it "is the first half of the postcode" do
        expect(Signature.new(:postcode => "SW1A 1AA").postal_district).to eq("SW1A")
        expect(Signature.new(:postcode => "E5C 2PL").postal_district).to eq("E5C")
        expect(Signature.new(:postcode => "E5 2PL").postal_district).to eq("E5")
        expect(Signature.new(:postcode => "E52 2PL").postal_district).to eq("E52")
        expect(Signature.new(:postcode => "SO22 2PL").postal_district).to eq("SO22")
      end

      it "handles the lack of spaces" do
        expect(Signature.new(:postcode => "SO222PL").postal_district).to eq("SO22")
      end

      it "handles lack of spaces for shorter codes" do
        expect(Signature.new(:postcode => "wn88en").postal_district).to eq("WN8")
        expect(Signature.new(:postcode => "hd58tf").postal_district).to eq("HD5")
      end

      it "handles case correctly" do
        expect(Signature.new(:postcode => "So222pL").postal_district).to eq("SO22")
      end

      it "is blank for non-standard postcodes" do
        expect(Signature.new(:postcode => "").postal_district).to eq("")
        expect(Signature.new(:postcode => "BFPO 1234").postal_district).to eq("")
      end
    end

    describe "uk_citizenship" do
      it "should require acceptance of uk_citizenship for a new record" do
        expect(FactoryGirl.build(:signature, :uk_citizenship => '1')).to be_valid
        expect(FactoryGirl.build(:signature, :uk_citizenship => '0')).not_to be_valid
        expect(FactoryGirl.build(:signature, :uk_citizenship => nil)).not_to be_valid
      end

      it "should not require acceptance of uk_citizenship for old records" do
        sig = FactoryGirl.create(:signature)
        sig.reload
        sig.uk_citizenship = '0'
        expect(sig).to be_valid
      end
    end
  end

  context "scopes" do
    let(:week_ago) { 1.week.ago }
    let(:two_days_ago) { 2.days.ago }
    let!(:petition) { FactoryGirl.create(:petition) }
    let!(:signature1) { FactoryGirl.create(:signature, :email => "person1@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :last_emailed_at => nil) }
    let!(:signature2) { FactoryGirl.create(:signature, :email => "person2@example.com", :petition => petition, :state => Signature::PENDING_STATE, :last_emailed_at => two_days_ago) }
    let!(:signature3) { FactoryGirl.create(:signature, :email => "person3@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :last_emailed_at => week_ago) }
    let!(:signature4) { FactoryGirl.create(:signature, :email => "person4@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :last_emailed_at => two_days_ago) }
    let!(:signature5) { FactoryGirl.create(:signature, :email => "person5@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :notify_by_email => false, :last_emailed_at => two_days_ago) }

    context "validated" do
      it "should return only validated signatures" do
        signatures = Signature.validated
        expect(signatures.size).to eq(5)
        expect(signatures).to include(signature1, signature3, signature4, signature5, petition.creator_signature)
      end
    end

    context "pending" do
      it "should return only pending signatures" do
        signatures = Signature.pending
        expect(signatures.size).to eq(1)
        expect(signatures).to include(signature2)
      end
    end

    context "need emailing" do
      it "should return only validated signatures who have opted in to receiving email updates" do
        expect(Signature.need_emailing(Time.now)).to include(signature1, signature3, signature4, petition.creator_signature)
        expect(Signature.need_emailing(two_days_ago)).to include(signature1, signature3, petition.creator_signature)
        expect(Signature.need_emailing(week_ago)).to include(signature1, petition.creator_signature)
      end
    end

    context "matching" do
      let!(:signature1) { FactoryGirl.create(:signature, name: "Joe Public", email: "person1@example.com", petition: petition, state: Signature::VALIDATED_STATE, last_emailed_at: nil) }

      it "should return a signature matching in name, email and petition_id" do
        signature = FactoryGirl.build(:signature, name: "Joe Public", email: "person1@example.com", petition: petition)
        expect(Signature.matching(signature)).to include(signature1)
      end

      it "should not return a signature matching in name, email and different petition" do
        signature = FactoryGirl.build(:signature, name: "Joe Public", email: "person1@example.com", petition_id: 2)
        expect(Signature.matching(signature)).to_not include(signature1)
      end

      it "should not return a signature matching in email, petition and different name" do
        signature = FactoryGirl.build(:signature, name: "Josey Public", email: "person1@example.com", petition: petition)
        expect(Signature.matching(signature)).to_not include(signature1)
      end
    end

    describe "for_email" do
      let!(:other_petition) { FactoryGirl.create(:petition) }
      let!(:other_signature) do
        FactoryGirl.create(:signature, :email => "person3@example.com",
        :petition => other_petition, :state => Signature::PENDING_STATE,
        :last_emailed_at => two_days_ago)
      end

      it "returns an empty set if the email is not found" do
        expect(Signature.for_email("notfound@example.com")).to eq([])
      end

      it "returns only signatures for the given email address" do
        expect(Signature.for_email("person3@example.com")).to eq(
          [signature3, other_signature]
        )
      end
    end

    describe "checking whether the signature is the creator" do
      let!(:petition) { FactoryGirl.create(:petition) }
      it "is the creator if the signature is listed as the creator signature" do
        expect(petition.creator_signature).to be_creator
      end

      it "is not the creator if the signature is not listed as the creator" do
        signature = FactoryGirl.create(:signature, :petition => petition)
        expect(signature).not_to be_creator
      end
    end
  end

  describe "#pending?" do
    it "returns true if the signature has a pending state" do
      signature = FactoryGirl.build(:pending_signature)
      expect(signature.pending?).to be_truthy
    end

    it "returns false if the signature is validated state" do
      signature = FactoryGirl.build(:validated_signature)
      expect(signature.pending?).to be_falsey
    end
  end

  describe "#validated?" do
    it "returns true if the signature has a validated state" do
      signature = FactoryGirl.build(:validated_signature)
      expect(signature.validated?).to be_truthy
    end

    it "returns false if the signature is pending state" do
      signature = FactoryGirl.build(:pending_signature)
      expect(signature.validated?).to be_falsey
    end
  end

  describe '#creator?' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:signature) { FactoryGirl.create(:signature, petition: petition) }
    let(:creator_signature) { petition.creator_signature }

    it 'is true if the signature is the creator_signature for the petition it belongs to' do
      expect(creator_signature.creator?).to be_truthy
    end

    it 'is false if the signature is not the creator_signature for the petition it belongs to' do
      expect(signature.creator?).to be_falsey
    end
  end

  describe '#sponsor?' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
    let(:sponsor_signature) { sponsor.create_signature!(FactoryGirl.attributes_for(:signature)) }
    let(:signature) { FactoryGirl.create(:signature, petition: petition) }

    it 'is true if the signature is a sponsor signature for the petition it belongs to' do
      expect(sponsor_signature.sponsor?).to be_truthy
    end

    it 'is false if the signature is not a sponsor signature for the petition it belongs to' do
      expect(signature.sponsor?).to be_falsey
    end
  end

  describe '#validate_from_token!' do
    subject { FactoryGirl.create(:pending_signature) }

    it 'returns false if the signature has no token' do
      subject.perishable_token = nil
      expect(subject.validate_from_token!('any-token')).to be_falsey
      expect(subject.validate_from_token!(nil)).to be_falsey
    end

    it 'returns false if the signature is already validated' do
      subject.state = Signature::VALIDATED_STATE
      expect(subject.validate_from_token!(subject.perishable_token)).to be_falsey
      expect(subject.validate_from_token!('any-token')).to be_falsey
      expect(subject.validate_from_token!(nil)).to be_falsey
    end

    context 'when the supplied token matches the signatures perishable_token' do
      let(:token) { subject.perishable_token }
      it 'returns true' do
        expect(subject.validate_from_token!(token)).to be_truthy
      end

      it 'removes the perishable token from the signature' do
        subject.validate_from_token!(token)
        expect(subject.perishable_token).to be_nil
      end

      it 'transitions the signature to the validated state' do
        subject.validate_from_token!(token)
        expect(subject).to be_validated
      end

      it 'timestamps the signature to say it was updated just now' do
        now = Chronic.parse("1 Jan 2011").utc
        # Unlike our code which uses Time.current, AR actually uses Time.now to do timestamping
        allow(Time).to receive(:now).and_return(now)

        subject.validate_from_token!(token)
        expect(subject.updated_at).to eq now
      end
    end

    context 'when the supplied token does not match the signatures perishable_token' do
      let(:token) { 'some-token-that-isnt-the-real-thing' }
      it 'returns false' do
        expect(subject.validate_from_token!(token)).to be_falsey
      end

      it 'leaves the perishable token on the signature' do
        subject.validate_from_token!(token)
        expect(subject.perishable_token).not_to be_nil
      end

      it 'leaves the signature in the pending state' do
        subject.validate_from_token!(token)
        expect(subject).to be_pending
      end
    end
  end

  describe "#constituency" do
    let(:api_url) { "http://data.parliament.uk/membersdataplatform/services/mnis/Constituencies" }
    let(:empty_body) {
      "<Constituencies/>"
    }
    let(:fake_body) {
      "<Constituencies>
        <Constituency><Name>Islington South and Finsbury</Name></Constituency>
       </Constituencies>"
    }
    let(:fake_body_multiple) {
      "<Constituencies>
        <Constituency><Name>Hackney North and Stoke Newington</Name></Constituency>
        <Constituency><Name>Hackney South and Shoreditch</Name></Constituency>
        <Constituency><Name>Holborn and St Pancras</Name></Constituency>
        <Constituency><Name>Islington North</Name></Constituency>
        <Constituency><Name>Islington South and Finsbury</Name></Constituency>
       </Constituencies>"
    }

    it "returns a constituency object for valid postcode" do
      stub_request(:get, "#{ api_url }/N11TY/").to_return(status: 200, body: fake_body)
      signature = FactoryGirl.build(:signature, postcode: 'N1 1TY')
      expect(signature.constituency).to be_kind_of(ConstituencyApi::Constituency)
    end
    
    it "returns the constituency for valid postcode" do
      stub_request(:get, "#{ api_url }/N11TY/").to_return(status: 200, body: fake_body)
      signature = FactoryGirl.build(:signature, postcode: 'N1 1TY')
      expect(signature.constituency).to eq ConstituencyApi::Constituency.new("Islington South and Finsbury")
    end
    
    it "returns the first constituency for postcode with prefix only eg N1" do
      stub_request(:get, "#{ api_url }/N1/").to_return(status: 200, body: fake_body_multiple)
      signature = FactoryGirl.build(:signature, postcode: 'N1')
      expect(signature.constituency).to eq ConstituencyApi::Constituency.new("Hackney North and Stoke Newington")
    end

    it "returns nil for invalid postcode" do
      stub_request(:get, "#{ api_url }/SW149RQ/").to_return(status: 200, body: empty_body)
      signature = FactoryGirl.build(:signature, postcode: 'SW14 9RQ')
      expect(signature.constituency).to be_nil
    end

    it "returns nil for timed out API request" do
      stub_request(:any, /.*data.parliament.uk.*/).to_timeout
      signature = FactoryGirl.build(:signature, postcode: 'N1 1TY')
      expect(signature.constituency).to be_nil
    end
    
    it "returns nil for unexpected API response" do
      stub_request(:get, "#{ api_url }/N1/").to_return(status: 500, body: fake_body)
      signature = FactoryGirl.build(:signature, postcode: 'N1')
      expect(signature.constituency).to be_nil
    end
  end
end
