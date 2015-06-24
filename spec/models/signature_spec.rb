require 'rails_helper'

RSpec.describe Signature, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:signature)).to be_valid
  end

  context "defaults" do
    it "has pending as default state" do
      s = Signature.new
      expect(s.state).to eq("pending")
    end

    it "generates perishable token" do
      s = FactoryGirl.create(:signature, :perishable_token => nil)
      expect(s.perishable_token).not_to be_nil
    end

    it "sets notify_by_email to truthy" do
      s = Signature.new
      expect(s.notify_by_email).to be_truthy
    end

    it "generates unsubscription token" do
      s = FactoryGirl.create(:signature, :unsubscribe_token=> nil)
      expect(s.unsubscribe_token).not_to be_nil
    end
  end

  RSpec::Matchers.define :have_valid do |field|
    match do |actual|
      actual.valid?
      expect(actual.errors[field]).to be_empty
    end
  end

  context "custom attribute setters" do
    describe "#postcode=" do
      let(:signature) { FactoryGirl.build(:signature) }

      it "removes all whitespace" do
        signature.postcode = " N1  1TY  "
        expect(signature.postcode).to eq "N11TY"
      end
      it "upcases the postcode" do
        signature.postcode = "n11ty "
        expect(signature.postcode).to eq "N11TY"
      end
      it "removes whitespaces and upcase the postcode" do
        signature.postcode = "   N1  1ty "
        expect(signature.postcode).to eq "N11TY"
      end
    end
    describe "#email=" do
      let(:signature) { FactoryGirl.build(:signature) }

      it "downcases the email" do
        signature.email = "JOE@PUBLIC.COM"
        expect(signature.email).to eq "joe@public.com"
      end
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:name).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:email).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:country).with_message(/must be completed/) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:constituency_id).is_at_most(255) }

    it "validates format of email" do
      s = FactoryGirl.build(:signature, :email => 'joe@example.com')
      expect(s).to have_valid(:email)
    end

    it "does not allow invalid email" do
      s = FactoryGirl.build(:signature, :email => 'not an email')
      expect(s).not_to have_valid(:email)
    end

    describe "uniqueness of email" do
      let(:petition) { FactoryGirl.create(:open_petition) }
      let(:other_petition) { FactoryGirl.create(:open_petition) }
      let(:attributes) do
        {
          name:     "Suzy Signer",
          petition: petition,
          postcode: "SW1A 1AA",
          email:    "foo@example.com"
        }
      end

      context "when a signature already exists with the same email address" do
        before do
          FactoryGirl.create(:signature, attributes.merge(name: "Suzy Signer"))
        end

        it "doesn't allow a second signature with the same email address and the same name" do
          signature = FactoryGirl.build(:signature, attributes)
          expect(signature).not_to have_valid(:email)
        end

        it "does allow a second signature with the same email address but a different name" do
          signature = FactoryGirl.build(:signature, attributes.merge(name: "Sam Signer"))
          expect(signature).to have_valid(:email)
        end

        it "is scoped to a petition" do
          signature = FactoryGirl.build(:signature, attributes.merge(petition: other_petition))
          expect(signature).to have_valid(:email)
        end

        it "ignores extra whitespace at the end of the name" do
          signature = FactoryGirl.build(:signature, attributes.merge(name: "Suzy Signer "))
          expect(signature).not_to have_valid(:email)
        end

        it "ignores extra whitespace at the beginning of the name" do
          signature = FactoryGirl.build(:signature, attributes.merge(name: " Suzy Signer"))
          expect(signature).not_to have_valid(:email)
        end

        it "only allows the second email if the postcode is the same" do
          signature = FactoryGirl.build(:signature, attributes.merge(name: "Sam Signer", postcode: "SW1A 1AB"))
          expect(signature).not_to have_valid(:email)
        end

        it "ignores the space on the postcode check" do
          signature = FactoryGirl.build(:signature, attributes.merge(name: "Sam Signer", postcode: "SW1A1AA"))
          expect(signature).to have_valid(:email)

          signature = FactoryGirl.build(:signature, attributes.merge(name: "Sam Signer", postcode: "SW1A1AB"))
          expect(signature).not_to have_valid(:email)
        end

        it "does a case insensitive postcode check" do
          signature = FactoryGirl.build(:signature, attributes.merge(name: "Sam Signer", postcode: "sw1a 1aa"))
          expect(signature).to have_valid(:email)
        end

        it "is case insensitive about the email validation" do
          signature = FactoryGirl.build(:signature, attributes.merge(email: "FOO@example.com"))
          expect(signature).not_to have_valid(:email)
        end
      end

      context "when two signatures already exist with the same email address" do
        before do
          FactoryGirl.create(:signature, attributes.merge(name: "Suzy Signer"))
          FactoryGirl.create(:signature, attributes.merge(name: "Sam Signer"))
        end

        it "doesn't allow a third signature with the same email address" do
          signature = FactoryGirl.build(:signature, attributes.merge(name: "Sarah Signer"))
          expect(signature).not_to have_valid(:email)
        end
      end
    end

    it "does not allow blank or unknown state" do
      s = FactoryGirl.build(:signature, :state => '')
      expect(s).not_to have_valid(:state)
      s.state = 'unknown'
      expect(s).not_to have_valid(:state)
    end

    it "allows known states" do
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
        s = FactoryGirl.build(:signature, :postcode => 'SW1A1AA')
        expect(s).to have_valid(:postcode)
      end
      it "recognises special postcodes" do
        expect(FactoryGirl.build(:signature, :postcode => 'BFPO 1234')).to have_valid(:postcode)
        expect(FactoryGirl.build(:signature, :postcode => 'XM4 5HQ')).to have_valid(:postcode)
        expect(FactoryGirl.build(:signature, :postcode => 'GIR 0AA')).to have_valid(:postcode)
      end
      it "does not allow prefix of postcode only" do
        s = FactoryGirl.build(:signature, :postcode => 'N1')
        expect(s).not_to have_valid(:postcode)
      end
      it "does not allow unrecognised postcodes" do
        s = FactoryGirl.build(:signature, :postcode => '90210')
        expect(s).not_to have_valid(:postcode)
      end
    end

    describe "uk_citizenship" do
      it "requires acceptance of uk_citizenship for a new record" do
        expect(FactoryGirl.build(:signature, :uk_citizenship => '1')).to be_valid
        expect(FactoryGirl.build(:signature, :uk_citizenship => '0')).not_to be_valid
        expect(FactoryGirl.build(:signature, :uk_citizenship => nil)).not_to be_valid
      end

      it "does not require acceptance of uk_citizenship for old records" do
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
    let!(:signature1) { FactoryGirl.create(:signature, :email => "person1@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :notify_by_email => true) }
    let!(:signature2) { FactoryGirl.create(:signature, :email => "person2@example.com", :petition => petition, :state => Signature::PENDING_STATE, :notify_by_email => true) }
    let!(:signature3) { FactoryGirl.create(:signature, :email => "person3@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :notify_by_email => false) }

    context "validated" do
      it "returns only validated signatures" do
        signatures = Signature.validated
        expect(signatures.size).to eq(3)
        expect(signatures).to include(signature1, signature3, petition.creator_signature)
      end
    end

    context "notify_by_email" do
      it "returns only signatures with notify_by_email: true" do
        signatures = Signature.notify_by_email
        expect(signatures.size).to eq(3)
        expect(signatures).to include(signature1, signature2, petition.creator_signature)
      end
    end

    context "pending" do
      it "returns only pending signatures" do
        signatures = Signature.pending
        expect(signatures.size).to eq(1)
        expect(signatures).to include(signature2)
      end
    end

    context "matching" do
      let!(:signature1) { FactoryGirl.create(:signature, name: "Joe Public", email: "person1@example.com", petition: petition, state: Signature::VALIDATED_STATE) }

      it "returns a signature matching in name, email and petition_id" do
        signature = FactoryGirl.build(:signature, name: "Joe Public", email: "person1@example.com", petition: petition)
        expect(Signature.matching(signature)).to include(signature1)
      end

      it "does not return a signature matching in name, email and different petition" do
        signature = FactoryGirl.build(:signature, name: "Joe Public", email: "person1@example.com", petition_id: 2)
        expect(Signature.matching(signature)).to_not include(signature1)
      end

      it "does not return a signature matching in email, petition and different name" do
        signature = FactoryGirl.build(:signature, name: "Josey Public", email: "person1@example.com", petition: petition)
        expect(Signature.matching(signature)).to_not include(signature1)
      end
    end

    describe "for_email" do
      let!(:other_petition) { FactoryGirl.create(:petition) }
      let!(:other_signature) do
        FactoryGirl.create(
          :signature,
          :email => "person3@example.com",
          :petition => other_petition,
          :state => Signature::PENDING_STATE
        )
      end

      it "returns an empty set if the email is not found" do
        expect(Signature.for_email("notfound@example.com")).to eq([])
      end

      it "returns only signatures for the given email address" do
        expect(Signature.for_email("person3@example.com")).to match_array(
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

  describe "#number" do
    let(:attributes) { FactoryGirl.attributes_for(:petition) }
    let(:creator) { FactoryGirl.create(:pending_signature) }
    let(:petition) do
      Petition.create(attributes) do |petition|
        petition.creator_signature = creator

        5.times do
          petition.signatures << FactoryGirl.create(:pending_signature)
        end
      end
    end

    let(:other_attributes) { FactoryGirl.attributes_for(:petition) }
    let(:other_creator) { FactoryGirl.create(:pending_signature) }
    let(:other_petition) do
      Petition.create(other_attributes) do |petition|
        petition.creator_signature = other_creator

        5.times do
          petition.signatures << FactoryGirl.create(:pending_signature)
        end
      end
    end

    before do
      petition.signatures.each { |s| s.validate! }
      petition.publish!

      other_petition.signatures.each { |s| s.validate! }
      other_petition.publish!
    end

    it "returns the signature number" do
      signature = FactoryGirl.create(:pending_signature, petition: petition)
      signature.validate!

      expect(petition.signature_count).to eq(7)
      expect(signature.number).to eq(7)
    end

    it "is scoped to the petition" do
      other_signature = FactoryGirl.create(:pending_signature, petition: other_petition)
      other_signature.validate!

      signature = FactoryGirl.create(:pending_signature, petition: petition)
      signature.validate!

      expect(other_petition.signature_count).to eq(7)
      expect(other_signature.number).to eq(7)

      expect(petition.signature_count).to eq(7)
      expect(signature.number).to eq(7)
    end

    it "remains the same after another signature is added" do
      signature = FactoryGirl.create(:pending_signature, petition: petition)
      later_signature = FactoryGirl.create(:pending_signature, petition: petition)
      signature.validate!

      expect { later_signature.validate! }.not_to change{ signature.number }
    end

    it "remains the same even if an earlier signature is validated" do
      earlier_signature = FactoryGirl.create(:pending_signature, petition: petition)
      signature = FactoryGirl.create(:pending_signature, petition: petition)
      signature.validate!

      expect { earlier_signature.validate! }.not_to change{ signature.number }
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

  describe '#validate!' do
    let(:signature) { FactoryGirl.create(:pending_signature, petition: petition, created_at: 2.days.ago, updated_at: 2.days.ago) }

    context "when the petition is open" do
      let(:petition) { FactoryGirl.create(:open_petition, created_at: 2.days.ago, updated_at: 2.days.ago) }

      it "transitions the signature to the validated state" do
        signature.validate!
        expect(signature).to be_validated
      end

      it "timestamps the signature to say it was updated just now" do
        signature.validate!
        expect(signature.updated_at).to be_within(1.second).of(Time.current)
      end

      it "timestamps the signature to say it was validated just now" do
        signature.validate!
        expect(signature.validated_at).to be_within(1.second).of(Time.current)
      end

      it "increments the petition count" do
        expect{ signature.validate! }.to change{ petition.reload.signature_count }.by(1)
      end

      it "updates the petition to say it was updated just now" do
        signature.validate!
        expect(petition.reload.updated_at).to be_within(1.second).of(Time.current)
      end

      it "updates the petition to say it was last signed at just now" do
        signature.validate!
        expect(petition.reload.last_signed_at).to be_within(1.second).of(Time.current)
      end

      it "doesn't increment the petition count twice" do
        signature.validate!
        expect{ signature.validate! }.to change{ petition.reload.signature_count }.by(0)
      end

      it 'tells the relevant constituency petition journal to record a new signature' do
        expect(ConstituencyPetitionJournal).to receive(:record_new_signature_for).with(signature)
        signature.validate!
      end

      it 'does not talk to the constituency petition journal if the signature is not pending' do
        expect(ConstituencyPetitionJournal).not_to receive(:record_new_signature_for)
        signature.state = Signature::VALIDATED_STATE
        signature.validate!
      end
    end

    context "when the petition is pending" do
      let(:petition) { FactoryGirl.create(:pending_petition, created_at: 2.days.ago, updated_at: 2.days.ago) }
      let(:creator_signature) { petition.creator_signature }

      it "transitions the creator signature to the validated state" do
        expect{ signature.validate! }.to change{ creator_signature.reload.validated? }.from(false).to(true)
      end

      it 'tells the relevant constituency petition journal to record a new signature' do
        expect(ConstituencyPetitionJournal).to receive(:record_new_signature_for).with(creator_signature)
        expect(ConstituencyPetitionJournal).to receive(:record_new_signature_for).with(signature)
        signature.validate!
      end

      it 'does not talk to the constituency petition journal if the signature is not pending' do
        expect(ConstituencyPetitionJournal).not_to receive(:record_new_signature_for)
        signature.state = Signature::VALIDATED_STATE
        signature.validate!
      end
    end
  end

  include ConstituencyApiHelpers::ApiLevel
  describe "#constituency" do
    let(:constituency1) { ConstituencyApi::Constituency.new('1234', "Shoreditch") }
    let(:constituency2) { ConstituencyApi::Constituency.new('1235', "Lambeth") }

    it "returns a constituency object from the API return array" do
      stub_constituency('N1 1TY', constituency1)
      signature = FactoryGirl.build(:signature, postcode: 'N1 1TY')
      expect(signature.constituency).to eq(constituency1)
    end

    it "returns the first object for multiple results" do
      stub_constituencies('N1', constituency1, constituency2)
      signature = FactoryGirl.build(:signature, postcode: 'N1')
      expect(signature.constituency).to eq(constituency1)
    end

    it "returns nil for invalid postcode" do
      stub_no_constituencies('SW149RQ')
      signature = FactoryGirl.build(:signature, postcode: 'SW14 9RQ')
      expect(signature.constituency).to be_nil
    end

    it "returns nil for unexpected API response" do
      stub_broken_api
      signature = FactoryGirl.build(:signature, postcode: 'N1')
      expect(signature.constituency).to be_nil
    end
  end

  describe 'set_constituency_id' do
    let(:signature) { FactoryGirl.build(:signature, postcode: 'SW1 1AA')}

    it 'sets the constituency_id based on the id of the constituency' do
      stub_constituency('SW1 1AA', '12345', 'North Idshire')
      signature.set_constituency_id
      expect(signature.constituency_id).to eq '12345'
    end

    it 'does not raise if the api fails' do
      stub_broken_api
      expect { signature.set_constituency_id }.not_to raise_error
      expect(signature.constituency_id).to be_nil
    end

    it 'leaves it blank if there are no constituencies found' do
      stub_no_constituencies('SW1 1AA')
      signature.set_constituency_id
      expect(signature.constituency_id).to be_nil
    end

    it 'chooses the first one if multiple constituencies are found' do
      constituency1 = ConstituencyApi::Constituency.new('1234', "Shoreditch")
      constituency2 = ConstituencyApi::Constituency.new('1235', "Lambeth")

      stub_constituencies('SW1 1AA', constituency2, constituency1)
      signature.set_constituency_id
      expect(signature.constituency_id).to eq '1235'
    end
  end

  describe 'store_constituency_id' do
    let(:signature) { FactoryGirl.build(:signature, postcode: 'SW1 1AA')}

    it 'saves the instance and sets the constituency id' do
      stub_constituency('SW1 1AA', '12345', 'North Idshire')
      signature.store_constituency_id
      expect(signature.constituency_id).to eq '12345'
      expect(signature).to be_persisted
    end

    it 'does not save the instance if it did not set a constituency id' do
      stub_no_constituencies('SW1 1AA')
      signature.store_constituency_id
      expect(signature.constituency_id).to be_nil
      expect(signature).not_to be_persisted
    end
  end

  describe 'email sent receipts' do
    it { is_expected.to have_one(:email_sent_receipt).dependent(:destroy) }

    describe '#email_sent_receipt!' do
      let(:signature) { FactoryGirl.create(:signature) }

      it 'returns the existing db object if one exists' do
        existing = signature.create_email_sent_receipt
        expect(signature.email_sent_receipt!).to eq existing
      end

      it 'returns a newly created instance if does not already exist' do
        instance = signature.email_sent_receipt!
        expect(instance).to be_present
        expect(instance).to be_a(EmailSentReceipt)
        expect(instance.signature).to eq signature
        expect(instance.signature).to be_persisted
      end
    end

    describe '#get_email_sent_at_for' do
      let(:signature) { FactoryGirl.create(:validated_signature) }
      let(:receipt) { signature.email_sent_receipt! }
      let(:the_stored_time) { 6.days.ago }

      it 'returns nil when nothing has been stamped for the supplied name' do
        expect(signature.get_email_sent_at_for('government_response')).to be_nil
      end

      it 'returns the stored timestamp for the supplied name' do
        receipt.update_column('government_response', the_stored_time)
        expect(signature.get_email_sent_at_for('government_response')).to eq the_stored_time
      end
    end

    describe '#set_email_sent_at_for' do
      include ActiveSupport::Testing::TimeHelpers

      let(:signature) { FactoryGirl.create(:validated_signature) }
      let(:receipt) { signature.email_sent_receipt! }
      let(:the_stored_time) { 6.days.ago }

      it 'sets the stored timestamp for the supplied name to the supplied time' do
        signature.set_email_sent_at_for('government_response', to: the_stored_time)
        expect(receipt.government_response).to eq the_stored_time
      end

      it 'sets the stored timestamp for the supplied name to the current time if none is supplied' do
        travel_to the_stored_time do
          signature.set_email_sent_at_for('government_response')
          expect(receipt.government_response).to eq Time.current
        end
      end
    end

    describe "#need_emailing_for" do
      let!(:a_signature) { FactoryGirl.create(:validated_signature) }
      let!(:another_signature) { FactoryGirl.create(:validated_signature) }
      let(:since_timestamp) { 5.days.ago }

      subject { Signature.need_emailing_for('government_response', since: since_timestamp) }

      it "does not return those that do not want to be emailed" do
        a_signature.update_attribute(:notify_by_email, false)
        expect(subject).not_to include a_signature
      end

      it 'does not return unvalidated signatures' do
        another_signature.update_column(:state, Signature::PENDING_STATE)
        expect(subject).not_to include another_signature
      end

      it 'does not return signatures that have a sent receipt newer than the petitions requested receipt' do
        another_signature.set_email_sent_at_for('government_response', to: since_timestamp + 1.day)
        expect(subject).not_to include another_signature
      end

      it 'does not return signatures that have a sent receipt equal to the petitions requested receipt' do
        another_signature.set_email_sent_at_for('government_response', to: since_timestamp)
        expect(subject).not_to include another_signature
      end

      it 'does return signatures that have a sent receipt older than the petitions requested receipt' do
        another_signature.set_email_sent_at_for('government_response', to: since_timestamp - 1.day)
        expect(subject).to include another_signature
      end

      it 'returns signatures that have no sent receipt, or null for the requested timestamp in their receipt' do
        another_signature.email_sent_receipt!.destroy && another_signature.reload
        a_signature.email_sent_receipt!.update_column('government_response', nil)
        expect(subject).to match_array [a_signature, another_signature]
      end
    end
  end
end

