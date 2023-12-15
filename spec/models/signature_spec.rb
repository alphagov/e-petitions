require 'rails_helper'

RSpec.describe Signature, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:signature)).to be_valid
  end

  around do |example|
    perform_enqueued_jobs do
      example.call
    end
  end

  before do
    FactoryBot.create(:constituency, :london_and_westminster)
    FactoryBot.create(:location, code: "GB", name: "United Kingdom")
  end

  context "defaults" do
    it "has pending as default state" do
      s = Signature.new
      expect(s.state).to eq("pending")
    end

    it "generates perishable token" do
      s = FactoryBot.create(:signature, :perishable_token => nil)
      expect(s.perishable_token).not_to be_nil
    end

    it "sets notify_by_email to falsey" do
      s = Signature.new
      expect(s.notify_by_email).to be_falsey
    end

    it "generates unsubscription token" do
      s = FactoryBot.create(:signature, :unsubscribe_token => nil)
      expect(s.unsubscribe_token).not_to be_nil
    end

    it "generates signed token" do
      s = FactoryBot.create(:signature, :signed_token => nil)
      expect(s.signed_token).not_to be_nil
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
      let(:signature) { FactoryBot.build(:signature) }

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
      let(:signature) { FactoryBot.build(:signature) }

      it "downcases the email domain" do
        signature.email = "JOE@PUBLIC.COM"
        expect(signature.email).to eq "JOE@public.com"
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition) }
    it { is_expected.to belong_to(:invalidation).optional }
  end

  describe "callbacks" do
    context "when the signature is destroyed" do
      let!(:petition) { FactoryBot.create(:open_petition) }
      let!(:creator) { petition.creator }

      before do
        5.times do
          FactoryBot.create(:validated_signature, petition: petition)
        end
      end

      context "and the signature is the creator" do
        it "cancels the destroy" do
          expect(creator.destroy).to eq(false)
        end
      end

      context "and the signature is not the creator" do
        let(:country_journal) { CountryPetitionJournal.for(petition, "GB") }
        let(:constituency_journal) { ConstituencyPetitionJournal.for(petition, "3415") }

        let!(:signature) {
          FactoryBot.create(
            :validated_signature,
            petition: petition,
            constituency_id: "3415",
            location_code: "GB"
          )
        }

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

      context "and the signature is invalidated" do
        let(:country_journal) { CountryPetitionJournal.for(petition, "GB") }
        let(:constituency_journal) { ConstituencyPetitionJournal.for(petition, "3415") }

        let!(:signature) {
          FactoryBot.create(
            :invalidated_signature,
            petition: petition,
            constituency_id: "3415",
            location_code: "GB"
          )
        }

        it "doesn't decrement the petition signature count" do
          expect(petition.signature_count).to eq(6)
          expect{ signature.destroy }.not_to change{ petition.reload.signature_count }
        end

        it "doesn't decrement the country journal signature count" do
          expect(petition.signature_count).to eq(6)
          expect{ signature.destroy }.not_to change{ country_journal.reload.signature_count }
        end

        it "doesn't decrement the constituency journal signature count" do
          expect(petition.signature_count).to eq(6)
          expect{ signature.destroy }.not_to change{ constituency_journal.reload.signature_count }
        end
      end
    end

    context "when the signature is created" do
      let!(:petition) { FactoryBot.create(:open_petition) }
      let!(:signature) { petition.signatures.build(attributes) }
      let(:email) { "foo@example.com" }
      let(:location_code) { "GB" }
      let(:postcode) { "SW1A 1AA" }

      let(:attributes) do
        {
          name: "Suzy Signer",
          email: email,
          postcode: postcode,
          location_code: location_code,
          uk_citizenship: "1"
        }
      end

      context "and the signature is a duplicate" do
        before do
          petition.signatures.create!(attributes)
        end

        it "raises an ActiveRecord::RecordNotUnique exception" do
          expect { signature.save }.to raise_exception(ActiveRecord::RecordNotUnique)
        end
      end

      context "and the email is blank" do
        let(:email) { "" }

        it "doesn't set the uuid column" do
          expect {
            signature.save
          }.not_to change {
            signature.uuid
          }
        end
      end

      context "and the email is set" do
        let(:email) { "alice@example.com" }

        it "sets the uuid column" do
          expect {
            signature.save
          }.to change {
            signature.uuid
          }.from(nil).to("6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6")
        end
      end

      context "and the email is normalized" do
        let!(:domain_1) { Domain.create(name: "example.com", strip_extension: "+", strip_characters: ".") }
        let!(:domain_2) { Domain.create(name: "example.co.uk", canonical_domain: domain_1) }

        let(:email) { "alice.smith+petitions@example.co.uk" }

        before do
          allow(Site).to receive(:disable_plus_address_check?).and_return(true)
        end

        it "sets the canonical_email column" do
          expect {
            signature.save
          }.to change {
            signature.canonical_email
          }.from(nil).to("alicesmith@example.com")
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
    it { is_expected.to allow_value("Please click this petition.parliament.uk for a special offer").for(:name) }
    it { is_expected.not_to allow_value("Please click this http://petition.parliament.uk for a special offer").for(:name) }
    it { is_expected.to allow_value("GB").for(:location_code) }
    it { is_expected.not_to allow_value("United Kingdom").for(:location_code) }

    it "validates format of email" do
      s = FactoryBot.build(:signature, :email => 'joe@example.com')
      expect(s).to have_valid(:email)
    end

    it "does not allow invalid email" do
      s = FactoryBot.build(:signature, :email => 'not an email')
      expect(s).not_to have_valid(:email)
    end

    it "doesn't allow local email addresses" do
      s = FactoryBot.build(:signature, :email => 'admin')
      expect(s).not_to have_valid(:email)
    end

    it "does not allow emails using plus addresses" do
      signature = FactoryBot.build(:signature, email: 'foobar+petitions@example.com')
      expect(signature).not_to have_valid(:email)
      expect(signature.errors.messages[:email]).to include("You can’t use ‘plus addressing’ in your email address")
    end

    it "does not allow blank or unknown state" do
      s = FactoryBot.build(:signature, :state => '')
      expect(s).not_to have_valid(:state)
      s.state = 'unknown'
      expect(s).not_to have_valid(:state)
    end

    it "allows known states" do
      s = FactoryBot.build(:signature)
      %w(pending validated ).each do |state|
        s.state = state
        expect(s).to have_valid(:state)
      end
    end

    describe "postcode" do
      it "requires a postcode for a UK address" do
        expect(FactoryBot.build(:signature, :postcode => 'SW1A 1AA')).to be_valid
        expect(FactoryBot.build(:signature, :postcode => '')).not_to be_valid
      end

      it "does not require a postcode for non-UK addresses" do
        expect(FactoryBot.build(:signature, :location_code => "GB", :postcode => '')).not_to be_valid
        expect(FactoryBot.build(:signature, :location_code => "US", :postcode => '')).to be_valid
      end

      it "checks the format of postcode" do
        s = FactoryBot.build(:signature, :postcode => 'SW1A1AA')
        expect(s).to have_valid(:postcode)
      end

      it "recognises special postcodes" do
        expect(FactoryBot.build(:signature, :postcode => 'BFPO 1234')).to have_valid(:postcode)
        expect(FactoryBot.build(:signature, :postcode => 'XM4 5HQ')).to have_valid(:postcode)
        expect(FactoryBot.build(:signature, :postcode => 'GIR 0AA')).to have_valid(:postcode)
      end

      it "does not allow prefix of postcode only" do
        s = FactoryBot.build(:signature, :postcode => 'N1')
        expect(s).not_to have_valid(:postcode)
      end

      it "does not allow unrecognised postcodes" do
        s = FactoryBot.build(:signature, :postcode => '90210')
        expect(s).not_to have_valid(:postcode)
      end

      it "does not allow postcodes longer than 255 characters for non-UK addresses" do
        s = FactoryBot.build(:signature, :location_code => "US", :postcode => "1" * 256)
        expect(s).not_to have_valid(:postcode)
      end
    end

    describe "uk_citizenship" do
      it "requires acceptance of uk_citizenship for a new record" do
        expect(FactoryBot.build(:signature, :uk_citizenship => '1')).to be_valid
        expect(FactoryBot.build(:signature, :uk_citizenship => '0')).not_to be_valid
        expect(FactoryBot.build(:signature, :uk_citizenship => nil)).not_to be_valid
      end

      it "does not require acceptance of uk_citizenship for old records" do
        sig = FactoryBot.create(:signature)
        sig.reload
        sig.uk_citizenship = '0'
        expect(sig).to be_valid
      end
    end
  end

  describe "scopes" do
    let(:week_ago) { 1.week.ago }
    let(:two_days_ago) { 2.days.ago }
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:signature1) { FactoryBot.create(:validated_signature, email: "person1@example.com", petition: petition, notify_by_email: true) }
    let!(:signature2) { FactoryBot.create(:pending_signature, email: "person2@example.com", petition: petition, notify_by_email: true) }
    let!(:signature3) { FactoryBot.create(:validated_signature, email: "person3@example.com", petition: petition, notify_by_email: false) }
    let!(:signature4) { FactoryBot.create(:invalidated_signature, email: "person4@example.com", petition: petition, notify_by_email: false) }
    let!(:signature5) { FactoryBot.create(:fraudulent_signature, email: "person4@example.com", petition: petition, notify_by_email: false) }

    describe "validated" do
      it "returns only validated signatures" do
        signatures = Signature.validated
        expect(signatures.size).to eq(3)
        expect(signatures).to include(signature1, signature3, petition.creator)
      end
    end

    describe "subscribed" do
      it "returns only signatures with notify_by_email: true" do
        signatures = Signature.subscribed
        expect(signatures.size).to eq(3)
        expect(signatures).to include(signature1, signature2, petition.creator)
      end
    end

    describe "pending" do
      it "returns only pending signatures" do
        signatures = Signature.pending
        expect(signatures.size).to eq(1)
        expect(signatures).to include(signature2)
      end
    end

    describe "invalidated" do
      it "returns only invalidated signatures" do
        signatures = Signature.invalidated
        expect(signatures.size).to eq(1)
        expect(signatures).to include(signature4)
      end
    end

    describe "fraudulent" do
      it "returns only fraudulent signatures" do
        signatures = Signature.fraudulent
        expect(signatures.size).to eq(1)
        expect(signatures).to include(signature5)
      end
    end

    describe "for_invalidating" do
      let(:petition) { FactoryBot.create(:open_petition) }

      subject do
        described_class.for_invalidating.to_a
      end

      it "returns pending signatures" do
        signature = FactoryBot.create(:pending_signature, petition: petition)
        expect(subject).to include(signature)
      end

      it "returns validated signatures" do
        signature = FactoryBot.create(:validated_signature, petition: petition)
        expect(subject).to include(signature)
      end

      it "doesn't return fraudulent signatures" do
        signature = FactoryBot.create(:fraudulent_signature, petition: petition)
        expect(subject).not_to include(signature)
      end

      it "doesn't return invalidated signatures" do
        signature = FactoryBot.create(:invalidated_signature, petition: petition)
        expect(subject).not_to include(signature)
      end
    end

    describe "for_email" do
      before do
        allow(Site).to receive(:disable_plus_address_check?).and_return(true)
      end

      let!(:other_petition) { FactoryBot.create(:petition) }
      let!(:other_signature) { FactoryBot.create(:pending_signature, email: "person3@example.com", petition: other_petition) }
      let!(:dotted_signature) { FactoryBot.create(:signature, email: "b.o.b@example.com", petition: other_petition) }
      let!(:plus_signature) { FactoryBot.create(:signature, email: "alice+3@example.com", petition: other_petition) }
      let!(:upcased_siganture) { FactoryBot.create(:signature, email: "Jo.Public@example.com", petition: other_petition) }

      it "returns an empty set if the email is not found" do
        expect(Signature.for_email("notfound@example.com")).to eq([])
      end

      it "returns only signatures for the given email address" do
        expect(Signature.for_email("person3@example.com")).to match_array([signature3, other_signature])
      end

      it "searches case-insensitively" do
        expect(Signature.for_email("Person3@example.com")).to match_array([signature3, other_signature])
      end

      it "normalizes dots in the local part" do
        expect(Signature.for_email("bob@example.com")).to match_array([dotted_signature])
      end

      it "normalizes pluses in the local part" do
        expect(Signature.for_email("alice@example.com")).to match_array([plus_signature])
      end

      it "normalizes case in the local part" do
        expect(Signature.for_email("jo.public@example.com")).to match_array([upcased_siganture])
      end
    end

    describe "checking whether the signature is the creator" do
      let!(:petition) { FactoryBot.create(:petition) }
      it "is the creator if the signature is listed as the creator signature" do
        expect(petition.creator).to be_creator
      end

      it "is not the creator if the signature is not listed as the creator" do
        signature = FactoryBot.create(:signature, :petition => petition)
        expect(signature).not_to be_creator
      end
    end
  end

  describe "read-only attributes" do
    [
      [:sponsor, true, false],
      [:creator, true, false]
    ].each do |attribute, value, new_value|

      describe "##{attribute}" do
        let(:signature) { FactoryBot.create(:signature, attribute => value) }
        let(:exception) { ActiveRecord::ActiveRecordError }
        let(:message) { "#{attribute} is marked as readonly" }

        it "can't be updated via update_column" do
          expect {
            signature.update_column(attribute, new_value)
          }.to raise_error(exception, message)
        end

        it "can't be updated via update" do
          expect {
            signature.update(attribute => value)
          }.not_to change {
            signature.reload.send(attribute)
          }
        end

        it "can't be updated via save" do
          expect {
            signature.send(:"#{attribute}=", new_value)
            signature.save
          }.not_to change {
            signature.reload.send(attribute)
          }
        end
      end

    end
  end

  describe ".search" do
    let(:scope) { double(:scope) }

    context "when searching with an ip address" do
      it "calls the for_ip scope and paginates the result" do
        expect(Signature).to receive(:for_ip).with("127.0.0.1").and_return(scope)
        expect(scope).to receive(:paginate).with(page: 1, per_page: 50)
        described_class.search("127.0.0.1")
      end

      context "and passing the page parameter" do
        it "calls the for_ip scope and paginates the result" do
          expect(Signature).to receive(:for_ip).with("127.0.0.1").and_return(scope)
          expect(scope).to receive(:paginate).with(page: 2, per_page: 50)
          described_class.search("127.0.0.1", page: "2")
        end
      end
    end

    context "when searching with a domain" do
      it "calls the for_domain scope and paginates the result" do
        expect(Signature).to receive(:for_domain).with("@example.com").and_return(scope)
        expect(scope).to receive(:paginate).with(page: 1, per_page: 50)
        described_class.search("@example.com")
      end

      context "and passing the page parameter" do
        it "calls the for_ip scope and paginates the result" do
          expect(Signature).to receive(:for_domain).with("@example.com").and_return(scope)
          expect(scope).to receive(:paginate).with(page: 2, per_page: 50)
          described_class.search("@example.com", page: "2")
        end
      end
    end

    context "when searching with an email address" do
      it "calls the for_email scope and paginates the result" do
        expect(Signature).to receive(:for_email).with("alice@example.com").and_return(scope)
        expect(scope).to receive(:paginate).with(page: 1, per_page: 50)
        described_class.search("alice@example.com")
      end

      context "and passing the page parameter" do
        it "calls the for_email scope and paginates the result" do
          expect(Signature).to receive(:for_email).with("alice@example.com").and_return(scope)
          expect(scope).to receive(:paginate).with(page: 2, per_page: 50)
          described_class.search("alice@example.com", page: "2")
        end
      end
    end

    context "when searching with a name" do
      it "calls the for_name scope and paginates the result" do
        expect(Signature).to receive(:for_name).with("Alice").and_return(scope)
        expect(scope).to receive(:paginate).with(page: 1, per_page: 50)
        described_class.search("Alice")
      end

      context "and passing the page parameter" do
        it "calls the for_name scope and paginates the result" do
          expect(Signature).to receive(:for_name).with("Alice").and_return(scope)
          expect(scope).to receive(:paginate).with(page: 2, per_page: 50)
          described_class.search("Alice", page: "2")
        end
      end
    end
  end

  describe ".validate!" do
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:creator) { petition.creator }

    before do
      5.times do
        FactoryBot.create(:validated_signature, petition: petition)
      end
    end

    context "when passed a signature id that doesn't exist" do
      let(:signature_ids) { [petition.signatures.maximum(:id) + 1] }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          described_class.invalidate!(signature_ids)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a pending signature" do
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      before do
        allow(described_class).to receive(:find).and_call_original
        allow(described_class).to receive(:find).with([signature.id]).and_return([signature])
        expect(signature).to receive(:validate!).and_call_original
      end

      it "transitions the signature to the validated state" do
        expect {
          described_class.validate!([signature.id])
        }.to change {
          signature.reload.validated?
        }.from(false).to(true)
      end
    end

    describe "using the default :force option" do
      context "with a fraudulent signature" do
        let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition) }

        before do
          allow(described_class).to receive(:find).and_call_original
          allow(described_class).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:validate!).and_call_original
        end

        it "doesn't transition the signature to the validated state" do
          expect {
            described_class.validate!([signature.id])
          }.not_to change {
            signature.reload.validated?
          }.from(false)
        end
      end

      context "with an invalidated signature" do
        let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition) }

        before do
          allow(described_class).to receive(:find).and_call_original
          allow(described_class).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:validate!).and_call_original
        end

        it "transitions the signature to the validated state" do
          expect {
            described_class.validate!([signature.id])
          }.not_to change {
            signature.reload.validated?
          }.from(false)
        end
      end
    end

    describe "using the force: true option" do
      context "with a fraudulent signature" do
        let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition) }

        before do
          allow(described_class).to receive(:find).and_call_original
          allow(described_class).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:validate!).and_call_original
        end

        it "transitions the signature to the validated state" do
          expect {
            described_class.validate!([signature.id], force: true)
          }.to change {
            signature.reload.validated?
          }.from(false).to(true)
        end
      end

      context "with an invalidated signature" do
        let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition) }

        before do
          allow(described_class).to receive(:find).and_call_original
          allow(described_class).to receive(:find).with([signature.id]).and_return([signature])
          expect(signature).to receive(:validate!).and_call_original
        end

        it "transitions the signature to the validated state" do
          expect {
            described_class.validate!([signature.id], force: true)
          }.to change {
            signature.reload.validated?
          }.from(false).to(true)
        end
      end
    end
  end

  describe ".invalidate!" do
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:creator) { petition.creator }

    before do
      5.times do
        FactoryBot.create(:validated_signature, petition: petition)
      end
    end

    context "when passed a signature id that doesn't exist" do
      let(:signature_ids) { [petition.signatures.maximum(:id) + 1] }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          described_class.invalidate!(signature_ids)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a validated signature" do
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }

      before do
        allow(described_class).to receive(:find).and_call_original
        allow(described_class).to receive(:find).with([signature.id]).and_return([signature])
        expect(signature).to receive(:invalidate!).and_call_original
      end

      it "transitions the signature to the invalidated state" do
        expect {
          described_class.invalidate!([signature.id])
        }.to change {
          signature.reload.invalidated?
        }.from(false).to(true)
      end
    end
  end

  describe ".subscribe!" do
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:creator) { petition.creator }

    before do
      5.times do
        FactoryBot.create(:validated_signature, petition: petition)
      end
    end

    context "when passed a signature id that doesn't exist" do
      let(:signature_ids) { [petition.signatures.maximum(:id) + 1] }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          described_class.subscribe!(signature_ids)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when trying to subscribe the creator" do
      it "doesn't raise an error" do
        expect {
          described_class.subscribe!([creator.id])
        }.not_to raise_error
      end
    end

    context "with a pending signature" do
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      it "doesn't raise an error" do
        expect {
          described_class.subscribe!([signature.id])
        }.not_to raise_error
      end
    end

    context "with a pending signature that isn't subscribed" do
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, notify_by_email: false) }

      it "subscribes the signature" do
        expect {
          described_class.subscribe!([signature.id])
        }.to change {
          signature.reload.unsubscribed?
        }.from(true).to(false)
      end
    end

    context "with a validated signature" do
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition, notify_by_email: false) }

      before do
        allow(described_class).to receive(:find).and_call_original
        allow(described_class).to receive(:find).with([signature.id]).and_return([signature])
        expect(signature).to receive(:update!).with(notify_by_email: true).and_call_original
      end

      it "subscribes the signature" do
        expect {
          described_class.subscribe!([signature.id])
        }.to change {
          signature.reload.unsubscribed?
        }.from(true).to(false)
      end
    end
  end

  describe ".unsubscribe!" do
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:creator) { petition.creator }

    before do
      5.times do
        FactoryBot.create(:validated_signature, petition: petition)
      end
    end

    context "when passed a signature id that doesn't exist" do
      let(:signature_ids) { [petition.signatures.maximum(:id) + 1] }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          described_class.unsubscribe!(signature_ids)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when trying to unsubscribe the creator" do
      it "raises an error" do
        expect {
          described_class.unsubscribe!([creator.id])
        }.to raise_error(RuntimeError, "Can't unsubscribe the creator signature")
      end
    end

    context "with a pending signature" do
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      it "raises an error" do
        expect {
          described_class.unsubscribe!([signature.id])
        }.to raise_error(RuntimeError, "Can't unsubscribe a pending signature")
      end
    end

    context "with a validated signature" do
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }

      before do
        allow(described_class).to receive(:find).and_call_original
        allow(described_class).to receive(:find).with([signature.id]).and_return([signature])
        expect(signature).to receive(:update!).with(notify_by_email: false).and_call_original
      end

      it "unsubscribes the signature" do
        expect {
          described_class.unsubscribe!([signature.id])
        }.to change {
          signature.reload.unsubscribed?
        }.from(false).to(true)
      end
    end
  end

  describe ".destroy!" do
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:creator) { petition.creator }

    before do
      5.times do
        FactoryBot.create(:validated_signature, petition: petition)
      end
    end

    context "when passed a signature id that doesn't exist" do
      let(:signature_ids) { [petition.signatures.maximum(:id) + 1] }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect {
          described_class.destroy!(signature_ids)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when trying to delete the creator" do
      let(:signature_ids) { [creator.id] }

      it "raises an ActiveRecord::RecordNotDestroyed error" do
        expect {
          described_class.destroy!(signature_ids)
        }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end

    context "when the signature is not the creator" do
      let(:country_journal) { CountryPetitionJournal.for(petition, "GB") }
      let(:constituency_journal) { ConstituencyPetitionJournal.for(petition, "3415") }

      let!(:signature) {
        FactoryBot.create(
          :validated_signature,
          petition: petition,
          constituency_id: "3415",
          location_code: "GB"
        )
      }

      it "decrements the petition signature count" do
        expect {
          described_class.destroy!([signature.id])
        }.to change {
          petition.reload.signature_count
        }.from(7).to(6)
      end

      it "decrements the country journal signature count" do
        expect {
          described_class.destroy!([signature.id])
        }.to change {
          country_journal.reload.signature_count
        }.by(-1)
      end

      it "decrements the constituency journal signature count" do
        expect {
          described_class.destroy!([signature.id])
        }.to change {
          constituency_journal.reload.signature_count
        }.by(-1)
      end
    end

    context "when one signature fails" do
      let(:signatures) { [petition.signatures.last, creator] }
      let(:signature_ids) { signatures.map(&:id) }

      before do
        allow(described_class).to receive(:find).with(signature_ids).and_return(signatures)
      end

      it "raises an ActiveRecord::RecordNotDestroyed error" do
        expect {
          described_class.destroy!(signature_ids)
        }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end

      it "doesn't destroy any signatures" do
        expect {
          begin
            described_class.destroy!(signature_ids)
          rescue ActiveRecord::RecordNotDestroyed => e
            0
          end
        }.not_to change {
          petition.reload.signatures.count
        }
      end
    end
  end

  describe ".missing_constituency_id" do
    let!(:signature_1) { FactoryBot.create(:validated_signature, validated_at: 2.weeks.ago) }
    let!(:signature_2) { FactoryBot.create(:validated_signature, constituency_id: "3415") }
    let!(:signature_3) { FactoryBot.create(:validated_signature, location_code: "US") }
    let!(:signature_4) { FactoryBot.create(:validated_signature) }

    subject { described_class.missing_constituency_id(since: 1.week.ago) }

    it "doesn't include signatures from before the cut-off date" do
      expect(subject).not_to include(signature_1)
    end

    it "doesn't include signatures that have a constituency_id" do
      expect(subject).not_to include(signature_2)
    end

    it "doesn't include signatures that are not in the UK" do
      expect(subject).not_to include(signature_3)
    end

    it "includes signatures that need their constituency_id set" do
      expect(subject).to include(signature_4)
    end

    context "when not supplying the cut-off date" do
      subject { described_class.missing_constituency_id }

      it "includes all signatures that need their constituency_id set" do
        expect(subject).to include(signature_1)
      end
    end
  end

  describe ".fraudulent_domains" do
    subject do
      described_class.fraudulent_domains
    end

    before do
      FactoryBot.create(:fraudulent_signature, email: "alice@foo.com")
      FactoryBot.create(:fraudulent_signature, email: "bob@bar.com")
      FactoryBot.create(:fraudulent_signature, email: "charlie@foo.com")
    end

    it "returns a hash of domains and counts in descending order" do
      expect(subject).to be_an_instance_of(Hash)
      expect(subject.to_a).to eq([["foo.com", 2], ["bar.com", 1]])
    end
  end

  describe ".trending_domains" do
    let!(:petition) { FactoryBot.create(:open_petition, open_at: 2.weeks.ago, creator_attributes: { validated_at: 2.weeks.ago } ) }

    before do
      FactoryBot.create(:validated_signature, petition: petition, email: "alice@foo.com", validated_at: 30.minutes.ago)
      FactoryBot.create(:validated_signature, petition: petition, email: "bob@bar.com", validated_at: 30.minutes.ago)
      FactoryBot.create(:validated_signature, petition: petition, email: "charlie@foo.com", validated_at: 30.minutes.ago)
    end

    it "returns a hash of domains and counts in descending order" do
      domains = described_class.trending_domains

      expect(domains).to be_an_instance_of(Hash)
      expect(domains.to_a).to eq([["foo.com", 2], ["bar.com", 1]])
    end

    it "ignores pending signatures" do
      FactoryBot.create(:pending_signature, petition: petition, email: "derek@foo.com", created_at: 30.minutes.ago)
      domains = described_class.trending_domains

      expect(domains.to_a).to eq([["foo.com", 2], ["bar.com", 1]])
    end

    it "ignores invalidated signatures" do
      FactoryBot.create(:invalidated_signature, petition: petition, email: "derek@foo.com", validated_at: 30.minutes.ago, invalidated_at: 10.minutes.ago)
      domains = described_class.trending_domains

      expect(domains.to_a).to eq([["foo.com", 2], ["bar.com", 1]])
    end

    it "ignores fraudulent signatures" do
      FactoryBot.create(:fraudulent_signature, petition: petition, email: "derek@foo.com", created_at: 30.minutes.ago)
      domains = described_class.trending_domains

      expect(domains.to_a).to eq([["foo.com", 2], ["bar.com", 1]])
    end

    it "can override the timespan" do
      FactoryBot.create(:validated_signature, petition: petition, email: "derek@foo.com", validated_at: 5.minutes.ago)
      domains = described_class.trending_domains(since: 10.minutes.ago)

      expect(domains.to_a).to eq([["foo.com", 1]])
    end

    it "can override the number returned" do
      domains = described_class.trending_domains(limit: 1)

      expect(domains.to_a).to eq([["foo.com", 2]])
    end
  end

  describe ".trending_ips" do
    let!(:petition) { FactoryBot.create(:open_petition, open_at: 2.weeks.ago, creator_attributes: { validated_at: 2.weeks.ago } ) }

    before do
      FactoryBot.create(:validated_signature, petition: petition, ip_address: "10.0.1.1", validated_at: 30.minutes.ago)
      FactoryBot.create(:validated_signature, petition: petition, ip_address: "192.168.1.1", validated_at: 30.minutes.ago)
      FactoryBot.create(:validated_signature, petition: petition, ip_address: "10.0.1.1", validated_at: 30.minutes.ago)
    end

    it "returns a hash of ip addresses and counts in descending order" do
      ip_addresses = described_class.trending_ips

      expect(ip_addresses).to be_an_instance_of(Hash)
      expect(ip_addresses.to_a).to eq([["10.0.1.1", 2], ["192.168.1.1", 1]])
    end

    it "ignores pending signatures" do
      FactoryBot.create(:pending_signature, petition: petition, ip_address: "10.0.1.1", created_at: 30.minutes.ago)
      ip_addresses = described_class.trending_ips

      expect(ip_addresses.to_a).to eq([["10.0.1.1", 2], ["192.168.1.1", 1]])
    end

    it "ignores invalidated signatures" do
      FactoryBot.create(:invalidated_signature, petition: petition, ip_address: "10.0.1.1", validated_at: 30.minutes.ago, invalidated_at: 10.minutes.ago)
      ip_addresses = described_class.trending_ips

      expect(ip_addresses.to_a).to eq([["10.0.1.1", 2], ["192.168.1.1", 1]])
    end

    it "ignores fraudulent signatures" do
      FactoryBot.create(:fraudulent_signature, petition: petition, ip_address: "10.0.1.1", created_at: 30.minutes.ago)
      ip_addresses = described_class.trending_ips

      expect(ip_addresses.to_a).to eq([["10.0.1.1", 2], ["192.168.1.1", 1]])
    end

    it "can override the timespan" do
      FactoryBot.create(:validated_signature, petition: petition, ip_address: "10.0.1.1", validated_at: 5.minutes.ago)
      ip_addresses = described_class.trending_ips(since: 10.minutes.ago)

      expect(ip_addresses.to_a).to eq([["10.0.1.1", 1]])
    end

    it "can override the number returned" do
      ip_addresses = described_class.trending_ips(limit: 1)

      expect(ip_addresses.to_a).to eq([["10.0.1.1", 2]])
    end
  end

  describe ".duplicate_emails" do
    let!(:petition) { FactoryBot.create(:open_petition) }

    context "when there are no duplicate emails" do
      it "returns zero" do
        expect(petition.signatures.duplicate_emails).to eq(0)
      end
    end

    context "when there are duplicate emails" do
      before do
        FactoryBot.create(:validated_signature, petition: petition, name: "Alice", email: "aliceandbob@example.com")
        FactoryBot.create(:validated_signature, petition: petition, name: "Bob", email: "aliceandbob@example.com")
      end

      it "returns the number of duplicate emails" do
        expect(petition.signatures.duplicate_emails).to eq(1)
      end
    end
  end

  describe ".pending_rate" do
    let!(:petition) { FactoryBot.create(:open_petition) }

    context "when there are no pending signatures" do
      it "returns zero" do
        expect(petition.signatures.pending_rate).to eq(0)
      end
    end

    context "when there are pending signatures" do
      before do
        FactoryBot.create(:pending_signature, petition: petition)
      end

      it "returns the number of duplicate emails" do
        expect(petition.signatures.pending_rate).to eq(50)
      end
    end
  end

  describe ".subscribers" do
    let!(:petition) { FactoryBot.create(:open_petition, creator_attributes: { notify_by_email: false }) }

    context "when there are no subscribed signatures" do
      before do
        FactoryBot.create(:validated_signature, petition: petition, notify_by_email: false)
      end

      it "returns zero" do
        expect(petition.signatures.subscribers).to eq(0)
      end
    end

    context "when there are subscribed signatures" do
      before do
        FactoryBot.create(:validated_signature, petition: petition, notify_by_email: true)
      end

      it "returns the number of duplicate emails" do
        expect(petition.signatures.subscribers).to eq(1)
      end
    end
  end

  describe ".not_anonymized" do
    subject do
      described_class.not_anonymized
    end

    context "when there are no signatures not anonymized" do
      let!(:signature) { FactoryBot.create(:signature, creator: true, anonymized_at: 1.week.ago) }

      it "returns an empty array" do
        expect(subject.to_a).to eq([])
      end
    end

    context "when there are signatures not anonymized" do
      let!(:signature) { FactoryBot.create(:signature, creator: true, anonymized_at: nil) }

      it "returns an array of signatures" do
        expect(subject.to_a).to eq([signature])
      end
    end
  end

  describe "#number" do
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:creator) { petition.creator }
    let!(:other_petition) { FactoryBot.create(:open_petition) }
    let!(:other_creator) { petition.creator }

    before do
      5.times do
        FactoryBot.create(:validated_signature, petition: petition)
      end

      5.times do
        FactoryBot.create(:validated_signature, petition: other_petition)
      end
    end

    it "returns the signature number" do
      signature = FactoryBot.create(:pending_signature, petition: petition)
      signature.validate!

      expect(signature.petition.reload.signature_count).to eq(7)
      expect(signature.number).to eq(7)
    end

    it "is scoped to the petition" do
      other_signature = FactoryBot.create(:pending_signature, petition: other_petition)
      other_signature.validate!

      signature = FactoryBot.create(:pending_signature, petition: petition)
      signature.validate!

      expect(other_signature.petition.reload.signature_count).to eq(7)
      expect(other_signature.number).to eq(7)

      expect(signature.petition.reload.signature_count).to eq(7)
      expect(signature.number).to eq(7)
    end

    it "remains the same after another signature is added" do
      signature = FactoryBot.create(:pending_signature, petition: petition)
      later_signature = FactoryBot.create(:pending_signature, petition: petition)
      signature.validate!

      expect { later_signature.validate! }.not_to change{ signature.number }
    end

    it "remains the same even if an earlier signature is validated" do
      earlier_signature = FactoryBot.create(:pending_signature, petition: petition)
      signature = FactoryBot.create(:pending_signature, petition: petition)
      signature.validate!

      expect { earlier_signature.validate! }.not_to change{ signature.number }
    end
  end

  describe "#pending?" do
    it "returns true if the signature has a pending state" do
      signature = FactoryBot.build(:pending_signature)
      expect(signature.pending?).to be_truthy
    end

    (Signature::STATES - [Signature::PENDING_STATE]).each do |state|
      it "returns false if the signature is #{state} state" do
        signature = FactoryBot.build(:"#{state}_signature")
        expect(signature.pending?).to be_falsey
      end
    end
  end

  describe "#fraudulent?" do
    it "returns true if the signature has a fraudulent state" do
      signature = FactoryBot.build(:fraudulent_signature)
      expect(signature.fraudulent?).to be_truthy
    end

    (Signature::STATES - [Signature::FRAUDULENT_STATE]).each do |state|
      it "returns false if the signature is #{state} state" do
        signature = FactoryBot.build(:"#{state}_signature")
        expect(signature.fraudulent?).to be_falsey
      end
    end
  end

  describe "#validated?" do
    it "returns true if the signature has a validated state" do
      signature = FactoryBot.build(:validated_signature)
      expect(signature.validated?).to be_truthy
    end

    (Signature::STATES - [Signature::VALIDATED_STATE]).each do |state|
      it "returns false if the signature is #{state} state" do
        signature = FactoryBot.build(:"#{state}_signature")
        expect(signature.validated?).to be_falsey
      end
    end
  end

  describe "#invalidated?" do
    it "returns true if the signature has an invalidated state" do
      signature = FactoryBot.build(:invalidated_signature)
      expect(signature.invalidated?).to be_truthy
    end

    (Signature::STATES - [Signature::INVALIDATED_STATE]).each do |state|
      it "returns false if the signature is #{state} state" do
        signature = FactoryBot.build(:"#{state}_signature")
        expect(signature.invalidated?).to be_falsey
      end
    end
  end

  describe '#creator?' do
    let(:petition) { FactoryBot.create(:petition) }
    let(:signature) { FactoryBot.create(:signature, petition: petition) }
    let(:creator) { petition.creator }

    it 'is true if the signature is the creator for the petition it belongs to' do
      expect(creator.creator?).to be_truthy
    end

    it 'is false if the signature is not the creator for the petition it belongs to' do
      expect(signature.creator?).to be_falsey
    end
  end

  describe '#sponsor?' do
    let(:petition) { FactoryBot.create(:petition) }
    let(:sponsor) { FactoryBot.create(:sponsor, petition: petition) }
    let(:signature) { FactoryBot.create(:signature, petition: petition) }

    it 'is true if the signature is a sponsor signature for the petition it belongs to' do
      expect(sponsor.sponsor?).to be_truthy
    end

    it 'is false if the signature is not a sponsor signature for the petition it belongs to' do
      expect(signature.sponsor?).to be_falsey
    end
  end

  describe '#validate!' do
    let(:signature) { FactoryBot.create(:pending_signature, attributes) }
    let(:location_code) { "GB" }
    let(:postcode) { "SW1A 1AA" }

    let (:attributes) do
      {
        petition: petition,
        name: "Suzy Signer",
        email: "suzy@example.com",
        postcode: postcode,
        location_code: location_code,
        uk_citizenship: "1",
        created_at: 2.days.ago,
        updated_at: 2.days.ago
      }
    end

    context "when the petition is open" do
      let(:petition) do
        FactoryBot.create(:open_petition,
          created_at: 2.days.ago,
          updated_at: 2.days.ago,
          last_signed_at: 1.days.ago,
          creator_attributes: {
            validated_at: 2.days.ago
          }
        )
      end

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

      it "generates a signed_token if it's missing" do
        signature.update_column(:signed_token, nil)

        expect {
          signature.validate!
        }.to change {
          signature.reload[:signed_token]
        }.from(nil).to(be_present)
      end

      it "retries if the schema has changed" do
        expect(signature).to receive(:lock!).once.and_raise(ActiveRecord::PreparedStatementCacheExpired)
        expect(signature).to receive(:lock!).once.and_call_original
        expect(signature.class.connection).to receive(:clear_cache!).once

        signature.validate!
        expect(signature).to be_validated
      end

      it "raises ActiveRecord::PreparedStatementCacheExpired if it fails twice" do
        expect(signature).to receive(:lock!).twice.and_raise(ActiveRecord::PreparedStatementCacheExpired)
        expect{ signature.validate! }.to raise_error(ActiveRecord::PreparedStatementCacheExpired)
      end

      context "and the signer is from the UK" do
        let(:location_code) { "GB" }

        context "and the postcode is valid" do
          let(:postcode) { "SW1A 1AA" }

          it "calls the Constituency API and sets the constituency_id" do
            expect(Constituency).to receive(:find_by_postcode).with("SW1A1AA").and_call_original

            signature.validate!

            expect(signature).to be_validated
            expect(signature.constituency_id).to eq("3415")
          end
        end

        context "and the postcode is invalid" do
          let(:postcode) { "SW14 9RQ" }

          it "calls the Constituency API but doesn't set constituency_id" do
            expect(Constituency).to receive(:find_by_postcode).with("SW149RQ").and_call_original

            signature.validate!

            expect(signature).to be_validated
            expect(signature.constituency_id).to be_nil
          end
        end
      end

      context "and the signer is not from the UK" do
        let(:location_code) { "US" }

        context "and the postcode is set" do
          let(:postcode) { "12345" }

          it "doesn't call the Constituency API and doesn't set constituency_id" do
            expect(Constituency).not_to receive(:find_by_postcode)

            signature.validate!

            expect(signature).to be_validated
            expect(signature.constituency_id).to be_nil
          end
        end

        context "and the postcode is blank" do
          let(:postcode) { "" }

          it "doesn't call the Constituency API and doesn't set constituency_id" do
            expect(Constituency).not_to receive(:find_by_postcode)

            signature.validate!

            expect(signature).to be_validated
            expect(signature.constituency_id).to be_nil
          end
        end
      end

      context "and the signature is fraudulent" do
        let(:signature) { FactoryBot.create(:fraudulent_signature, attributes) }

        it "doesn't transition the signature to the validated state" do
          expect {
            signature.validate!
          }.not_to change {
            signature.reload.validated?
          }.from(false)
        end

        it "doesn't increment the petition count" do
          expect {
            signature.validate!
          }.not_to change {
            petition.reload.signature_count
          }
        end
      end

      context "and the signature is invalidated" do
        let(:signature) { FactoryBot.create(:invalidated_signature, attributes) }

        it "doesn't transition the signature to the validated state" do
          expect {
            signature.validate!
          }.not_to change {
            signature.reload.validated?
          }.from(false)
        end

        it "doesn't increment the petition count" do
          expect {
            signature.validate!
          }.not_to change {
            petition.reload.signature_count
          }
        end
      end

      describe "using the force: true option" do
        context "and the signature is fraudulent" do
          let(:signature) { FactoryBot.create(:fraudulent_signature, attributes) }

          it "transitions the signature to the validated state" do
            expect {
              signature.validate!(force: true)
            }.to change {
              signature.reload.validated?
            }.from(false).to(true)
          end

          it "increments the petition count" do
            expect {
              signature.validate!(force: true)
            }.to change {
              petition.reload.signature_count
            }.by(1)
          end
        end

        context "and the signature is invalidated" do
          let(:signature) { FactoryBot.create(:invalidated_signature, attributes) }

          it "transitions the signature to the validated state" do
            expect {
              signature.validate!(force: true)
            }.to change {
              signature.reload.validated?
            }.from(false).to(true)
          end

          it "increments the petition count" do
            expect {
              signature.validate!(force: true)
            }.to change {
              petition.reload.signature_count
            }.by(1)
          end
        end
      end

      describe "using the :request option" do
        let(:signature) { FactoryBot.create(:pending_signature, attributes) }
        let(:request) { double(:request, remote_ip: "12.34.56.78") }

        it "records the ip address of the validation request" do
          expect {
            signature.validate!(request: request)
          }.to change {
            signature.reload.validated_ip
          }.from(nil).to("12.34.56.78")
        end
      end
    end
  end

  describe "#just_validated?" do
    let(:petition) { FactoryBot.create(:petition) }
    let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

    context "when the signature is pending" do
      it "returns false" do
        expect(signature.just_validated?).to eq(false)
      end
    end

    context "when the signature has just been validated" do
      before do
        signature.validate!
      end

      it "returns true" do
        expect(signature.just_validated?).to eq(true)
      end
    end

    context "when the signature has been reloaded after validation" do
      before do
        signature.validate!
        signature.reload
      end

      it "returns false" do
        expect(signature.just_validated?).to eq(false)
      end
    end
  end

  describe "#validated_before?" do
    let(:petition) { FactoryBot.create(:petition) }
    let(:timestamp) { 15.minutes.ago }

    %w[pending fraudulent invalidated].each do |state|
      context "when the signature is #{state}" do
        let(:signature) { FactoryBot.create(:"#{state}_signature", petition: petition) }

        it "returns false" do
          expect(signature.validated_before?(timestamp)).to eq(false)
        end
      end
    end

    context "when the signature has been validated within the last 15 minutes" do
      let(:signature) { FactoryBot.create(:validated_signature, validated_at: 5.minutes.ago, petition: petition) }

      it "returns false" do
        expect(signature.validated_before?(timestamp)).to eq(false)
      end
    end

    context "when the signature has been validated over 15 minutes ago" do
      let(:signature) { FactoryBot.create(:validated_signature, validated_at: 30.minutes.ago, petition: petition) }

      it "returns true" do
        expect(signature.validated_before?(timestamp)).to eq(true)
      end
    end
  end

  describe '#invalidate!' do
    let!(:petition) { FactoryBot.create(:open_petition, created_at: 2.days.ago, updated_at: 2.days.ago) }
    let!(:signature) { FactoryBot.create(:validated_signature, petition: petition, created_at: 2.days.ago, updated_at: 2.days.ago) }
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
      expect(signature).to receive(:lock!).once.and_raise(ActiveRecord::PreparedStatementCacheExpired)
      expect(signature).to receive(:lock!).once.and_call_original
      expect(signature.class.connection).to receive(:clear_cache!).once

      signature.invalidate!
      expect(signature).to be_invalidated
    end

    it "raises ActiveRecord::PreparedStatementCacheExpired if it fails twice" do
      expect(signature).to receive(:lock!).twice.and_raise(ActiveRecord::PreparedStatementCacheExpired)
      expect{ signature.invalidate! }.to raise_error(ActiveRecord::PreparedStatementCacheExpired)
    end

    context "when the signature is pending" do
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      it "doesn't decrement the petition count" do
        expect{ signature.invalidate! }.not_to change{ petition.reload.signature_count }
      end

      it "doesn't update the constituency journal" do
        expect(ConstituencyPetitionJournal).not_to receive(:invalidate_signature_for)
        signature.invalidate!
      end

      it "doesn't update the country journal" do
        expect(CountryPetitionJournal).not_to receive(:invalidate_signature_for)
        signature.invalidate!
      end
    end
  end

  describe "#save" do
    let(:petition) { FactoryBot.create(:petition, creator_attributes: { name: "Alice", email: "aliceandbob@example.com" }) }

    before do
      FactoryBot.create(:validated_signature, name: "Bob", email: "aliceandbob@example.com", petition: petition)
    end

    context "when the new creator hasn't already signed" do
      it "saves the new name" do
        expect(petition.update(creator_attributes: { name: "Fred" })).to be_truthy
      end
    end

    context "when the new creator has already signed" do
      it "doesn't save the new name" do
        expect(petition.update(creator_attributes: { name: "Bob" })).to be_falsey
      end

      it "adds an error to the name attribute" do
        expect {
          petition.update(creator_attributes: { name: "Bob" })
        }.to change {
          petition.creator.errors[:name]
        }.from([]).to(["Bob has already signed this petition using aliceandbob@example.com"])
      end
    end
  end

  describe "#anonymized?" do
    context "when anonymized_at is nil" do
      let(:signature) { FactoryBot.build(:signature, anonymized_at: nil) }

      it "return false" do
        expect(signature.anonymized?).to eq(false)
      end
    end

    context "when anonymized_at is not nil" do
      let(:signature) { FactoryBot.build(:signature, anonymized_at: 1.week.ago) }

      it "return true" do
        expect(signature.anonymized?).to eq(true)
      end
    end
  end

  describe "#anonymize!" do
    let!(:timestamp) { Time.current.beginning_of_day }

    it "anonymizes the name" do
      signature = FactoryBot.create(:signature, name: "Jo Public")

      expect {
        signature.anonymize!(timestamp)
      }.to change {
        signature.reload.name
      }.from("Jo Public").to("Signature #{signature.id}")
    end

    it "anonymizes the email" do
      signature = FactoryBot.create(:signature, email: "jo.public@gmail.com")

      expect {
        signature.anonymize!(timestamp)
      }.to change {
        signature.reload.email
      }.from("jo.public@gmail.com").to("signature-#{signature.id}@example.com")
    end

    it "anonymizes the ip address" do
      signature = FactoryBot.create(:signature, ip_address: "12.34.56.78")

      expect {
        signature.anonymize!(timestamp)
      }.to change {
        signature.reload.ip_address
      }.from("12.34.56.78").to("192.168.1.1")
    end

    it "sets the anonymized_at timestamp" do
      signature = FactoryBot.create(:signature)

      expect {
        signature.anonymize!(timestamp)
      }.to change {
        signature.reload.anonymized_at
      }.from(nil).to(timestamp)
    end

    it "anonymizes the postcode" do
      constituency = FactoryBot.create(:constituency, :coventry_north_east)
      signature = FactoryBot.create(:signature, postcode: "CV66PS", constituency_id: "3427")

      expect {
        signature.anonymize!(timestamp)
      }.to change {
        signature.reload.postcode
      }.from("CV66PS").to("CV21HN")
    end

    context "when the constituency is missing" do
      context "and the signature is in the UK" do
        it "sets the postcode to ZZ993WZ" do
          signature = FactoryBot.create(:signature, postcode: "SW1A1AA", location_code: "GB", constituency_id: nil)

          expect {
            signature.anonymize!(timestamp)
          }.to change {
            signature.reload.postcode
          }.from("SW1A1AA").to("ZZ993WZ")
        end
      end

      context "and the signature is not in the UK" do
        it "sets the postcode to an empty string" do
          signature = FactoryBot.create(:signature, postcode: "12345", location_code: "US", constituency_id: nil)

          expect {
            signature.anonymize!(timestamp)
          }.to change {
            signature.reload.postcode
          }.from("12345").to("")
        end
      end
    end
  end

  describe "#unsubscribe" do
    let(:signature) { FactoryBot.create(:validated_signature, notify_by_email: subscribed) }
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
    let(:signature) { FactoryBot.create(:validated_signature) }

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
    let(:signature) { FactoryBot.create(:validated_signature) }

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

  describe "#subscribed?" do
    context "when the signature is pending" do
      let(:signature) { FactoryBot.build(:pending_signature, notify_by_email: true) }

      it "returns false" do
        expect(signature.subscribed?).to eq(false)
      end
    end

    context "when the signature is validated" do
      context "and notify_by_email is true" do
        let(:signature) { FactoryBot.build(:validated_signature, notify_by_email: true) }

        it "returns true" do
          expect(signature.subscribed?).to eq(true)
        end
      end

      context "and notify_by_email is false" do
        let(:signature) { FactoryBot.build(:validated_signature, notify_by_email: false) }

        it "returns false" do
          expect(signature.subscribed?).to eq(false)
        end
      end
    end

    context "when the signature is fraudulent" do
      let(:signature) { FactoryBot.build(:fraudulent_signature, notify_by_email: true) }

      it "returns false" do
        expect(signature.subscribed?).to eq(false)
      end
    end

    context "when the signature is invalidated" do
      let(:signature) { FactoryBot.build(:invalidated_signature, notify_by_email: true) }

      it "returns false" do
        expect(signature.subscribed?).to eq(false)
      end
    end
  end

  describe "#constituency" do
    let(:signature) { FactoryBot.build(:signature, attributes) }
    let(:constituency) { signature.constituency }
    let(:location_code) { "GB" }

    let(:attributes) do
      { postcode: postcode, constituency_id: constituency_id }
    end

    context "when the constituency_id is not set" do
      let(:constituency_id) { nil }

      context "and the signature is not from the UK" do
        let(:postcode) { "12345" }

        it "returns nil" do
          expect(signature).to receive(:united_kingdom?).and_return(false)
          expect(Constituency).not_to receive(:find_by_postcode)
          expect(signature.constituency).to be_nil
        end
      end

      context "and the API returns a single result" do
        let(:postcode) { "N1 1TY" }

        before do
          stub_api_request_for("N11TY").to_return(api_response(:ok, "single"))
        end

        it "returns the correct constituency" do
          expect(Constituency).to receive(:find_by_postcode).with("N11TY").and_call_original
          expect(constituency.name).to eq("Islington South and Finsbury")
        end
      end

      context "and the API returns multiple result" do
        let(:postcode) { "N1" }

        before do
          stub_api_request_for("N1").to_return(api_response(:ok, "multiple"))
        end

        it "returns the correct constituency" do
          expect(Constituency).to receive(:find_by_postcode).with("N1").and_call_original
          expect(constituency.name).to eq("Hackney North and Stoke Newington")
        end
      end


      context "and the API returns no results" do
        let(:postcode) { "SW14 9RQ" }

        before do
          stub_api_request_for("SW149RQ").to_return(api_response(:ok, "no_results"))
        end

        it "returns nil" do
          expect(Constituency).to receive(:find_by_postcode).with("SW149RQ").and_call_original
          expect(constituency).to be_nil
        end
      end

      context "and the API raises an error" do
        let(:postcode) { "N1 1TY" }

        before do
          stub_api_request_for("N11TY").to_timeout
        end

        it "returns nil" do
          expect(Constituency).to receive(:find_by_postcode).with("N11TY").and_call_original
          expect(constituency).to be_nil
        end
      end
    end

    context "when the constituency_id is set" do
      let(:constituency_id) { "3415" }
      let(:postcode) { "SW1A 1AA" }

      it "searches the database for the constituency" do
        expect(Constituency).not_to receive(:find_by_postcode)
        expect(Constituency).to receive(:find_by_external_id).with("3415").and_call_original
        expect(constituency.name).to eq("Cities of London and Westminster")
      end
    end
  end

  describe "#signed_token" do
    let(:signature) { FactoryBot.create(:validated_signature) }

    context "when the underlying column is nil" do
      before do
        signature.update_column(:signed_token, nil)
      end

      it "generates and saves a new token" do
        expect {
          signature.signed_token
        }.to change {
          signature.reload[:signed_token]
        }.from(nil).to(be_present)
      end
    end

    context "when another process has updated the column" do
      let(:token) { SecureRandom.base58(20) }

      before do
        signature.update_column(:signed_token, nil)
      end

      it "returns the token from the database" do
        expect(signature).to receive(:signed_token?).and_return(true)
        expect(signature).to receive(:read_attribute).with(:signed_token).and_return(token)
        expect(signature.signed_token).to eq(token)
      end
    end
  end

  describe 'email sent timestamps' do
    describe '#get_email_sent_at_for' do
      let(:signature) { FactoryBot.create(:validated_signature) }
      let(:the_stored_time) { 6.days.ago }

      [
        %w[government_response government_response_email_at],
        %w[debate_scheduled debate_scheduled_email_at],
        %w[debate_outcome debate_outcome_email_at],
        %w[petition_email petition_email_at],
        %w[petition_mailshot petition_mailshot_at]
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
      let(:signature) { FactoryBot.create(:validated_signature) }
      let(:the_stored_time) { 6.days.ago }

      [
        %w[government_response government_response_email_at],
        %w[debate_scheduled debate_scheduled_email_at],
        %w[debate_outcome debate_outcome_email_at],
        %w[petition_email petition_email_at],
        %w[petition_mailshot petition_mailshot_at]
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
      let!(:a_signature) { FactoryBot.create(:validated_signature) }
      let!(:another_signature) { FactoryBot.create(:validated_signature) }
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

      context "when there is an additional scope" do
        let!(:coventry_signature) { FactoryBot.create(:validated_signature, constituency_id: "3427") }
        let!(:romford_signature) { FactoryBot.create(:validated_signature, constituency_id: "3703") }

        subject { Signature.need_emailing_for('petition_mailshot', since: since_timestamp, scope: { constituency_id: "3427" }) }

        it "returns signatures within the scope" do
          expect(subject).to include coventry_signature
        end

        it "does not return signatures outside the scope" do
          expect(subject).not_to include romford_signature
        end
      end
    end
  end

  describe "#email_count" do
    it "returns 0 for new signatures" do
      signature = FactoryBot.create(:pending_signature)
      expect(signature.email_count).to be(0)
    end
  end

  describe "#email_threshold_reached?" do
    let(:email_count_threshold) { 5 }

    it "returns false when the signature hasn't reached the threshold" do
      signature = FactoryBot.create(:validated_signature)
      expect(signature.email_threshold_reached?).to be false
    end

    it "returns true when the signature is at the email count threshold" do
      signature = FactoryBot.create(:validated_signature, email_count: email_count_threshold)
      expect(signature.email_threshold_reached?).to be true
    end
  end

  describe "#find_duplicate" do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:other_petition) { FactoryBot.create(:open_petition) }
    let(:signature) { petition.signatures.build(attributes) }
    let(:name) { "Suzy Signer" }
    let(:postcode) { "SW1A 1AA" }
    let(:email) { "foo@example.com" }

    let(:attributes) do
      {
        name: name,
        email: email,
        postcode: postcode,
        location_code: "GB",
        uk_citizenship: "1"
      }
    end

    context "when a signature doesn't already exist with the same email address" do
      it "returns nil" do
        expect(signature.find_duplicate).to be_nil
      end
    end

    context "when a signature already exists with the same email address" do
      before do
        petition.signatures.create!(
          name: "Suzy Signer",
          email: "foo@example.com",
          postcode: "SW1A 1AA",
          location_code: "GB",
          uk_citizenship: "1"
        )
      end

      context "and the name is the same" do
        it "returns the signature" do
          expect(signature.find_duplicate).to be_present
        end
      end

      context "and the name is the same but different case" do
        let(:name) { "suzy signer" }

        it "returns the signature" do
          expect(signature.find_duplicate).to be_present
        end
      end

      context "and the name is the same but with extra whitespace" do
        let(:name) { " Suzy  Signer " }

        it "returns the signature" do
          expect(signature.find_duplicate).to be_present
        end
      end

      context "and the name is different" do
        let(:name) { "Sam Signer" }

        it "returns nil" do
          expect(signature.find_duplicate).to be_nil
        end
      end

      context "and the postcode is different" do
        let(:postcode) { "SW1A 1AB" }

        it "returns the signature" do
          expect(signature.find_duplicate).to be_present
        end
      end

      context "and the name and postcode are different" do
        let(:name) { "Sam Signer" }
        let(:postcode) { "SW1A 1AB" }

        it "returns the signature" do
          expect(signature.find_duplicate).to be_present
        end
      end

      context "and the name is the same, but is scoped to a different petition" do
        let(:signature) { other_petition.signatures.build(attributes) }

        it "returns nil" do
          expect(signature.find_duplicate).to be_nil
        end
      end

      context "but the email is a different case" do
        let(:email) { "FOO@example.com" }

        it "returns the signature" do
          expect(signature.find_duplicate).to be_present
        end
      end
    end

    context "when two signatures already exists with the same email address" do
      before do
        petition.signatures.create!(
          name: "Suzy Signer",
          email: "foo@example.com",
          postcode: "SW1A 1AA",
          location_code: "GB",
          uk_citizenship: "1"
        )

        petition.signatures.create!(
          name: "Sam Signer",
          email: "foo@example.com",
          postcode: "SW1A 1AA",
          location_code: "GB",
          uk_citizenship: "1"
        )
      end

      context "and the name is the same" do
        it "returns the signature" do
          expect(signature.find_duplicate).to be_present
        end
      end

      context "and the name is different" do
        let(:name) { "Sue Signer" }

        it "returns the signature" do
          expect(signature.find_duplicate).to be_present
        end
      end
    end
  end

  describe "#find_duplicate!" do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:signature) { petition.signatures.build(attributes) }

    let(:attributes) do
      {
        name: "Suzy Signer",
        email: "foo@example.com",
        postcode: "SW1A 1AA",
        location_code: "GB",
        uk_citizenship: "1"
      }
    end

    context "when a duplicate signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect { signature.find_duplicate! }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when a duplicate signature does exist" do
      before do
        petition.signatures.create!(attributes)
      end

      it "returns the signature" do
        expect(signature.find_duplicate!).to be_present
      end
    end
  end
end
