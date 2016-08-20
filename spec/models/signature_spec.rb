require 'rails_helper'

RSpec.describe Signature, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:signature)).to be_valid
  end

  around do |example|
    perform_enqueued_jobs do
      example.call
    end
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

  describe "associations" do
    it { is_expected.to belong_to(:petition) }
    it { is_expected.to belong_to(:invalidation) }
  end

  describe "callbacks" do
    context "when the signature is destroyed" do
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

      before do
        petition.signatures.each { |s| s.validate! }
        petition.publish
      end

      context "when the signature is the creator" do
        it "cancels the destroy" do
          expect(creator.destroy).to eq(false)
        end
      end

      context "when the signature is not the creator" do
        let!(:country_journal) { FactoryGirl.create(:country_petition_journal, petition: petition) }
        let!(:constituency_journal) { FactoryGirl.create(:constituency_petition_journal, petition: petition) }

        let!(:signature) {
          FactoryGirl.create(
            :pending_signature,
            petition: petition,
            constituency_id: constituency_journal.constituency_id,
            location_code: country_journal.location_code
          )
        }

        before do
          signature.validate!
          petition.reload
        end

        it "decrements the petition signature count" do
          expect(petition.signature_count).to eq(7)
          expect{ signature.destroy }.to change{ petition.reload.signature_count }.by(-1)
        end

        it "decrements the country journal signature count" do
          expect(petition.signature_count).to eq(7)
          expect{ signature.destroy }.to change{ country_journal.reload.signature_count }.by(-1)
        end

        it "decrements the constituency journal signature count" do
          expect(petition.signature_count).to eq(7)
          expect{ signature.destroy }.to change{ constituency_journal.reload.signature_count }.by(-1)
        end
      end

      context "when the signature is invalidated" do
        let!(:country_journal) { FactoryGirl.create(:country_petition_journal, petition: petition) }
        let!(:constituency_journal) { FactoryGirl.create(:constituency_petition_journal, petition: petition) }

        let!(:signature) {
          FactoryGirl.create(
            :pending_signature,
            petition: petition,
            constituency_id: constituency_journal.constituency_id,
            location_code: country_journal.location_code
          )
        }

        before do
          signature.validate!
          signature.invalidate!
          petition.reload
        end

        it "doesn't decrement the petition signature count" do
          expect(petition.signature_count).to eq(6)
          expect{ signature.destroy }.not_to change{ petition.reload.signature_count }
        end

        it "decrements the country journal signature count" do
          expect(petition.signature_count).to eq(6)
          expect{ signature.destroy }.not_to change{ country_journal.reload.signature_count }
        end

        it "decrements the constituency journal signature count" do
          expect(petition.signature_count).to eq(6)
          expect{ signature.destroy }.not_to change{ constituency_journal.reload.signature_count }
        end
      end
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:name).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:email).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:location_code).with_message(/must be completed/) }
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

    it "does not allow emails using plus addresses" do
      signature = FactoryGirl.build(:signature, email: 'foobar+petitions@example.com')
      expect(signature).not_to have_valid(:email)
      expect(signature.errors.full_messages).to include("You can’t use ‘plus addressing’ in your email address")
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
        expect(FactoryGirl.build(:signature, :location_code => "GB", :postcode => '')).not_to be_valid
        expect(FactoryGirl.build(:signature, :location_code => "US", :postcode => '')).to be_valid
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

  describe "scopes" do
    let(:week_ago) { 1.week.ago }
    let(:two_days_ago) { 2.days.ago }
    let!(:petition) { FactoryGirl.create(:petition) }
    let!(:signature1) { FactoryGirl.create(:signature, :email => "person1@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :notify_by_email => true) }
    let!(:signature2) { FactoryGirl.create(:signature, :email => "person2@example.com", :petition => petition, :state => Signature::PENDING_STATE, :notify_by_email => true) }
    let!(:signature3) { FactoryGirl.create(:signature, :email => "person3@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :notify_by_email => false) }

    describe "validated" do
      it "returns only validated signatures" do
        signatures = Signature.validated
        expect(signatures.size).to eq(3)
        expect(signatures).to include(signature1, signature3, petition.creator_signature)
      end
    end

    describe "notify_by_email" do
      it "returns only signatures with notify_by_email: true" do
        signatures = Signature.notify_by_email
        expect(signatures.size).to eq(3)
        expect(signatures).to include(signature1, signature2, petition.creator_signature)
      end
    end

    describe "pending" do
      it "returns only pending signatures" do
        signatures = Signature.pending
        expect(signatures.size).to eq(1)
        expect(signatures).to include(signature2)
      end
    end

    describe "matching" do
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

    describe "for_invalidating" do
      let(:petition) { FactoryGirl.create(:open_petition) }

      subject do
        described_class.for_invalidating.to_a
      end

      it "returns pending signatures" do
        signature = FactoryGirl.create(:pending_signature, petition: petition)
        expect(subject).to include(signature)
      end

      it "returns validated signatures" do
        signature = FactoryGirl.create(:validated_signature, petition: petition)
        expect(subject).to include(signature)
      end

      it "doesn't return fraudulent signatures" do
        signature = FactoryGirl.create(:fraudulent_signature, petition: petition)
        expect(subject).not_to include(signature)
      end

      it "doesn't return invalidated signatures" do
        signature = FactoryGirl.create(:invalidated_signature, petition: petition)
        expect(subject).not_to include(signature)
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

      it "searches case-insensitively" do
        expect(Signature.for_email("Person3@example.com")).to match_array(
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

  describe ".petition_ids_with_invalid_signature_counts" do
    subject do
      described_class.petition_ids_with_invalid_signature_counts
    end

    context "when there are no petitions with invalid signature counts" do
      let!(:petition) { FactoryGirl.create(:open_petition) }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when there are petitions with invalid signature counts" do
      let!(:petition) { FactoryGirl.create(:open_petition, signature_count: 100) }

      it "returns an array of ids" do
        expect(described_class.petition_ids_with_invalid_signature_counts).to eq([petition.id])
      end
    end
  end

  describe ".fraudulent_domains" do
    subject do
      described_class.fraudulent_domains
    end

    before do
      FactoryGirl.create(:fraudulent_signature, email: "alice@foo.com")
      FactoryGirl.create(:fraudulent_signature, email: "bob@bar.com")
      FactoryGirl.create(:fraudulent_signature, email: "charlie@foo.com")
    end

    it "returns a hash of domains and counts in descending order" do
      expect(subject).to be_an_instance_of(Hash)
      expect(subject.to_a).to eq([["foo.com", 2], ["bar.com", 1]])
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
      petition.publish

      other_petition.signatures.each { |s| s.validate! }
      other_petition.publish
    end

    it "returns the signature number" do
      signature = FactoryGirl.create(:pending_signature, petition: petition)
      signature.validate!

      expect(signature.petition.reload.signature_count).to eq(7)
      expect(signature.number).to eq(7)
    end

    it "is scoped to the petition" do
      other_signature = FactoryGirl.create(:pending_signature, petition: other_petition)
      other_signature.validate!

      signature = FactoryGirl.create(:pending_signature, petition: petition)
      signature.validate!

      expect(other_signature.petition.reload.signature_count).to eq(7)
      expect(other_signature.number).to eq(7)

      expect(signature.petition.reload.signature_count).to eq(7)
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

    (Signature::STATES - [Signature::PENDING_STATE]).each do |state|
      it "returns false if the signature is #{state} state" do
        signature = FactoryGirl.build(:"#{state}_signature")
        expect(signature.pending?).to be_falsey
      end
    end
  end

  describe "#fraudulent?" do
    it "returns true if the signature has a fraudulent state" do
      signature = FactoryGirl.build(:fraudulent_signature)
      expect(signature.fraudulent?).to be_truthy
    end

    (Signature::STATES - [Signature::FRAUDULENT_STATE]).each do |state|
      it "returns false if the signature is #{state} state" do
        signature = FactoryGirl.build(:"#{state}_signature")
        expect(signature.fraudulent?).to be_falsey
      end
    end
  end

  describe "#validated?" do
    it "returns true if the signature has a validated state" do
      signature = FactoryGirl.build(:validated_signature)
      expect(signature.validated?).to be_truthy
    end

    (Signature::STATES - [Signature::VALIDATED_STATE]).each do |state|
      it "returns false if the signature is #{state} state" do
        signature = FactoryGirl.build(:"#{state}_signature")
        expect(signature.validated?).to be_falsey
      end
    end
  end

  describe "#invalidated?" do
    it "returns true if the signature has an invalidated state" do
      signature = FactoryGirl.build(:invalidated_signature)
      expect(signature.invalidated?).to be_truthy
    end

    (Signature::STATES - [Signature::INVALIDATED_STATE]).each do |state|
      it "returns false if the signature is #{state} state" do
        signature = FactoryGirl.build(:"#{state}_signature")
        expect(signature.invalidated?).to be_falsey
      end
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
        signature.update_columns(state: Signature::VALIDATED_STATE)
        signature.validate!
      end

      it 'tells the relevant country petition journal to record a new signature' do
        expect(CountryPetitionJournal).to receive(:record_new_signature_for).with(signature)
        signature.validate!
      end

      it 'does not talk to the country petition journal if the signature is not pending' do
        expect(CountryPetitionJournal).not_to receive(:record_new_signature_for)
        signature.update_columns(state: Signature::VALIDATED_STATE)
        signature.validate!
      end

      it "retries if the schema has changed" do
        expect(signature).to receive(:lock!).once.and_raise(PG::InFailedSqlTransaction)
        expect(signature).to receive(:lock!).once.and_call_original
        expect(signature.class.connection).to receive(:clear_cache!).once

        signature.validate!
        expect(signature).to be_validated
      end

      it "raises PG::InFailedSqlTransaction if it fails twice" do
        expect(signature).to receive(:lock!).twice.and_raise(PG::InFailedSqlTransaction)
        expect{ signature.validate! }.to raise_error(PG::InFailedSqlTransaction)
      end
    end
  end

  describe '#invalidate!' do
    let!(:petition) { FactoryGirl.create(:open_petition, created_at: 2.days.ago, updated_at: 2.days.ago) }
    let!(:signature) { FactoryGirl.create(:validated_signature, petition: petition, created_at: 2.days.ago, updated_at: 2.days.ago) }
    let(:now) { Time.current }

    it "transitions the signature to the validated state" do
      signature.invalidate!
      expect(signature).to be_invalidated
    end

    it "timestamps the signature to say it was updated just now" do
      signature.invalidate!
      expect(signature.updated_at).to be_within(1.second).of(Time.current)
    end

    it "sets notify_by_email to false" do
      expect {
        signature.invalidate!
      }.to change {
        signature.reload.notify_by_email?
      }.from(true).to(false)
    end

    it "timestamps the signature to say it was invalidated just now" do
      signature.invalidate!
      expect(signature.invalidated_at).to be_within(1.second).of(Time.current)
    end

    it "decrements the petition count" do
      expect{ signature.invalidate! }.to change{ petition.reload.signature_count }.by(-1)
    end

    it "updates the petition to say it was updated just now" do
      signature.invalidate!
      expect(petition.reload.updated_at).to be_within(1.second).of(Time.current)
    end

    it "doesn't decrement the petition count twice" do
      signature.invalidate!
      expect{ signature.invalidate! }.to change{ petition.reload.signature_count }.by(0)
    end

    it 'tells the relevant constituency petition journal to invalidate the signature' do
      expect(ConstituencyPetitionJournal).to receive(:invalidate_signature_for).with(signature, now)
      signature.invalidate!(now)
    end

    it 'does not talk to the constituency petition journal if the signature is not validated' do
      expect(ConstituencyPetitionJournal).not_to receive(:invalidate_signature_for)
      signature.update_columns(state: Signature::INVALIDATED_STATE)
      signature.invalidate!
    end

    it 'tells the relevant country petition journal to invalidate the signature' do
      expect(CountryPetitionJournal).to receive(:invalidate_signature_for).with(signature, now)
      signature.invalidate!(now)
    end

    it 'does not talk to the country petition journal if the signature is not validated' do
      expect(CountryPetitionJournal).not_to receive(:invalidate_signature_for)
      signature.update_columns(state: Signature::INVALIDATED_STATE)
      signature.invalidate!
    end

    it "retries if the schema has changed" do
      expect(signature).to receive(:lock!).once.and_raise(PG::InFailedSqlTransaction)
      expect(signature).to receive(:lock!).once.and_call_original
      expect(signature.class.connection).to receive(:clear_cache!).once

      signature.invalidate!
      expect(signature).to be_invalidated
    end

    it "raises PG::InFailedSqlTransaction if it fails twice" do
      expect(signature).to receive(:lock!).twice.and_raise(PG::InFailedSqlTransaction)
      expect{ signature.invalidate! }.to raise_error(PG::InFailedSqlTransaction)
    end
  end

  describe "#unsubscribe" do
    let(:signature) { FactoryGirl.create(:validated_signature, notify_by_email: subscribed) }
    let(:unsubscribe_token) { signature.unsubscribe_token }

    before do
      signature.unsubscribe!(unsubscribe_token)
    end

    context "when subcribed" do
      let(:subscribed) { true }

      it "changes the subscription status" do
        expect(signature.notify_by_email).to be_falsey
      end

      it "doesn't add an error to the :base attribute" do
        expect(signature.errors[:base]).to be_empty
      end
    end

    context "when already unsubcribed" do
      let(:subscribed) { false }

      it "doesn't change the subscription status" do
        expect(signature.notify_by_email).to be_falsey
      end

      it "adds an error to the :base attribute" do
        expect(signature.errors[:base]).to include("Already Unsubscribed")
      end
    end

    context "when token is invalid" do
      let(:subscribed) { true }
      let(:unsubscribe_token) { "invalid token" }

      it "doesn't change the subscription status" do
        expect(signature.notify_by_email).to be_truthy
      end

      it "adds an error to the :base attribute" do
        expect(signature.errors[:base]).to include("Invalid Unsubscribe Token")
      end
    end
  end

  describe "#already_unsubscribed?" do
    let(:signature) { FactoryGirl.create(:validated_signature) }

    context "when there is no error on the :base attribute" do
      it "returns false" do
        expect(signature.already_unsubscribed?).to be_falsey
      end
    end

    context "when there is an error on the :base attribute" do
      before do
        signature.errors.add(:base, "Already Unsubscribed")
      end

      it "returns true" do
        expect(signature.already_unsubscribed?).to be_truthy
      end
    end
  end

  describe "#invalid_unsubscribe_token?" do
    let(:signature) { FactoryGirl.create(:validated_signature) }

    context "when there is no error on the :base attribute" do
      it "returns false" do
        expect(signature.invalid_unsubscribe_token?).to be_falsey
      end
    end

    context "when there is an error on the :base attribute" do
      before do
        signature.errors.add(:base, "Invalid Unsubscribe Token")
      end

      it "returns true" do
        expect(signature.invalid_unsubscribe_token?).to be_truthy
      end
    end
  end

  describe "#constituency" do
    it "returns a constituency object from the API return array" do
      stub_api_request_for("N11TY").to_return(api_response(:ok, "single"))
      signature = FactoryGirl.build(:signature, postcode: 'N1 1TY')
      expect(signature.constituency).to eq(Constituency.find_by!(external_id: '3550'))
    end

    it "returns the first object for multiple results" do
      stub_api_request_for("N1").to_return(api_response(:ok, "multiple"))
      signature = FactoryGirl.build(:signature, postcode: 'N1')
      expect(signature.constituency).to eq(Constituency.find_by!(external_id: '3506'))
    end

    it "returns nil for invalid postcode" do
      stub_api_request_for("SW149RQ").to_return(api_response(:ok, "no_results"))
      signature = FactoryGirl.build(:signature, postcode: 'SW14 9RQ')
      expect(signature.constituency).to be_nil
    end

    it "returns nil for unexpected API response" do
      stub_api_request_for("N1").to_timeout
      signature = FactoryGirl.build(:signature, postcode: 'N1')
      expect(signature.constituency).to be_nil
    end
  end

  describe 'set_constituency_id' do
    let(:signature) { FactoryGirl.build(:signature, postcode: 'N1 1TY') }

    it 'sets the constituency_id based on the id of the constituency' do
      stub_api_request_for("N11TY").to_return(api_response(:ok, "single"))
      signature.set_constituency_id
      expect(signature.constituency_id).to eq '3550'
    end

    it 'does not raise if the api fails' do
      stub_api_request_for("N11TY").to_timeout
      expect { signature.set_constituency_id }.not_to raise_error
      expect(signature.constituency_id).to be_nil
    end

    it 'leaves it blank if there are no constituencies found' do
      stub_api_request_for("N11TY").to_return(api_response(:ok, "no_results"))
      signature.set_constituency_id
      expect(signature.constituency_id).to be_nil
    end

    it 'chooses the first one if multiple constituencies are found' do
      stub_api_request_for("N11TY").to_return(api_response(:ok, "multiple"))
      signature.set_constituency_id
      expect(signature.constituency_id).to eq '3506'
    end
  end

  describe 'store_constituency_id' do
    let(:signature) { FactoryGirl.build(:signature, postcode: 'N1 1TY')}

    it 'saves the instance and sets the constituency id' do
      stub_api_request_for("N11TY").to_return(api_response(:ok, "single"))
      signature.store_constituency_id
      expect(signature.constituency_id).to eq '3550'
      expect(signature).to be_persisted
    end

    it 'does not save the instance if it did not set a constituency id' do
      stub_api_request_for("N11TY").to_return(api_response(:ok, "no_results"))
      signature.store_constituency_id
      expect(signature.constituency_id).to be_nil
      expect(signature).not_to be_persisted
    end
  end

  describe 'email sent timestamps' do
    describe '#get_email_sent_at_for' do
      let(:signature) { FactoryGirl.create(:validated_signature) }
      let(:the_stored_time) { 6.days.ago }

      [
        %w[government_response government_response_email_at],
        %w[debate_scheduled debate_scheduled_email_at],
        %w[debate_outcome debate_outcome_email_at],
        %w[petition_email petition_email_at]
      ].each do |timestamp, column|

        context "when the timestamp '#{timestamp}' is not set" do
          it "returns nil" do
            expect(signature.get_email_sent_at_for(timestamp)).to be_nil
          end
        end

        context "when the timestamp '#{timestamp}' is set" do
          before do
            signature.update_column(column, the_stored_time)
          end

          it "returns the stored timestamp" do
            expect(signature.get_email_sent_at_for(timestamp)).to eq(the_stored_time)
          end
        end

      end
    end

    describe '#set_email_sent_at_for' do
      let(:signature) { FactoryGirl.create(:validated_signature) }
      let(:the_stored_time) { 6.days.ago }

      [
        %w[government_response government_response_email_at],
        %w[debate_scheduled debate_scheduled_email_at],
        %w[debate_outcome debate_outcome_email_at],
        %w[petition_email petition_email_at]
      ].each do |timestamp, column|

        context "when a time is supplied for timestamp '#{timestamp}'" do
          it "sets the column to the supplied time" do
            expect {
              signature.set_email_sent_at_for(timestamp, to: the_stored_time)
            }.to change {
              signature.reload[column]
            }.from(nil).to(be_within(0.001.second).of(the_stored_time))
          end
        end

        context "when a time is not supplied for timestamp '#{timestamp}'" do
          it "sets the column to the current time" do
            expect {
              signature.set_email_sent_at_for(timestamp)
            }.to change {
              signature.reload[column]
            }.from(nil).to(be_within(1.second).of(Time.current))
          end
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

      it "does not return unvalidated signatures" do
        another_signature.update_column(:state, Signature::PENDING_STATE)
        expect(subject).not_to include another_signature
      end

      it "does not return signatures that have a sent timestamp newer than the petitions requested receipt" do
        another_signature.set_email_sent_at_for('government_response', to: since_timestamp + 1.day)
        expect(subject).not_to include another_signature
      end

      it "does not return signatures that have a sent timestamp equal to the petitions requested receipt" do
        another_signature.set_email_sent_at_for('government_response', to: since_timestamp)
        expect(subject).not_to include another_signature
      end

      it "does return signatures that have a sent timestamp older than the petitions requested receipt" do
        another_signature.set_email_sent_at_for('government_response', to: since_timestamp - 1.day)
        expect(subject).to include another_signature
      end

      it "returns signatures that have null for the requested timestamp" do
        a_signature.update_column(:government_response_email_at, nil)
        expect(subject).to match_array [a_signature, another_signature]
      end
    end
  end
end

