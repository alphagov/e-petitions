require 'rails_helper'

RSpec.describe Archived::Signature, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:archived_signature)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(limit: 255, null: false) }
    it { is_expected.to have_db_column(:state).of_type(:string).with_options(limit: 20, default: "pending", null: false) }
    it { is_expected.to have_db_column(:perishable_token).of_type(:string).with_options(limit: 255) }
    it { is_expected.to have_db_column(:postcode).of_type(:string).with_options(limit: 255) }
    it { is_expected.to have_db_column(:ip_address).of_type(:string).with_options(limit: 20) }
    it { is_expected.to have_db_column(:petition_id).of_type(:integer) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:notify_by_email).of_type(:boolean).with_options(default: false) }
    it { is_expected.to have_db_column(:email).of_type(:string).with_options(limit: 255) }
    it { is_expected.to have_db_column(:unsubscribe_token).of_type(:string) }
    it { is_expected.to have_db_column(:constituency_id).of_type(:string) }
    it { is_expected.to have_db_column(:validated_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:number).of_type(:integer) }
    it { is_expected.to have_db_column(:location_code).of_type(:string).with_options(limit: 30) }
    it { is_expected.to have_db_column(:invalidated_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:invalidation_id).of_type(:integer) }
    it { is_expected.to have_db_column(:government_response_email_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:debate_scheduled_email_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:debate_outcome_email_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:petition_email_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:petition_mailshot_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:uuid).of_type(:uuid) }
    it { is_expected.to have_db_column(:creator).of_type(:boolean).with_options(default: false, null: false) }
    it { is_expected.to have_db_column(:sponsor).of_type(:boolean).with_options(default: false, null: false) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:constituency).with_primary_key(:external_id).optional }
    it { is_expected.to belong_to(:petition) }
    it { is_expected.to belong_to(:invalidation).optional }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:constituency_id]) }
    it { is_expected.to have_db_index([:petition_id]) }
    it { is_expected.to have_db_index([:created_at, :ip_address, :petition_id]) }
    it { is_expected.to have_db_index([:email, :petition_id, :name]).unique }
    it { is_expected.to have_db_index([:invalidation_id]) }
    it { is_expected.to have_db_index([:ip_address, :petition_id]) }
    it { is_expected.to have_db_index([:petition_id, :location_code]) }
    it { is_expected.to have_db_index([:petition_id]) }
    it { is_expected.to have_db_index([:state, :petition_id]) }
    it { is_expected.to have_db_index([:updated_at]) }
    it { is_expected.to have_db_index([:uuid]) }
    it { is_expected.to have_db_index([:validated_at]) }
  end

  describe "callbacks" do
    context "when the signature is destroyed" do
      let(:creator) { FactoryBot.build(:archived_signature, creator: true) }
      let(:petition) { FactoryBot.create(:archived_petition, creator: creator, signature_count: 6) }
      let(:signature) { petition.signatures.last }

      before do
        5.times do
          FactoryBot.create(:archived_signature, petition: petition)
        end
      end

      context "and the signature is the creator" do
        it "cancels the destroy" do
          expect(creator.destroy).to eq(false)
        end
      end

      context "and the signature is not the creator" do
        it "destroys the signature" do
          expect {
            signature.destroy
          }.to change {
            petition.reload.signatures.count
          }.from(6).to(5)
        end

        it "doesn't decrement the signature count" do
          expect {
            signature.destroy
          }.not_to change {
            petition.reload.signature_count
          }
        end
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:email).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:location_code).with_message(/must be completed/) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:constituency_id).is_at_most(255) }
    it { is_expected.to allow_values(*Archived::Signature::STATES).for(:state) }
    it { is_expected.not_to allow_values("unknown", "").for(:state) }
  end

  describe "read-only attributes" do
    [
      [:sponsor, true, false],
      [:creator, true, false]
    ].each do |attribute, value, new_value|

      describe "##{attribute}" do
        let(:signature) { FactoryBot.create(:archived_signature, attribute => value) }

        it "can't be updated via update_column" do
          expect {
            signature.update_column(attribute, new_value)
          }.to raise_error(ActiveRecord::ActiveRecordError, "#{attribute} is marked as readonly")
        end

        it "can't be mass-assigned" do
          expect {
            signature.update(attribute => value)
          }.to raise_error(ActiveRecord::ReadonlyAttributeError, attribute.to_s)
        end

        it "can't be assigned directly" do
          expect {
            signature.send(:"#{attribute}=", new_value)
          }.to raise_error(ActiveRecord::ReadonlyAttributeError, attribute.to_s)
        end
      end

    end
  end

  describe ".need_emailing_for" do
    let!(:petition) { FactoryBot.create(:archived_petition) }
    let!(:creator) { FactoryBot.create(:archived_signature, petition: petition, creator: true) }
    let!(:pending) { FactoryBot.create(:archived_signature, petition: petition, state: "pending") }
    let!(:fraudulent) { FactoryBot.create(:archived_signature, petition: petition, state: "fraudulent") }
    let!(:invalidated) { FactoryBot.create(:archived_signature, petition: petition, state: "invalidated") }
    let!(:subscribed) { FactoryBot.create(:archived_signature, petition: petition) }
    let!(:unsubscribed) { FactoryBot.create(:archived_signature, petition: petition, notify_by_email: false) }

    let(:requested_at) { 1.hour.ago }

    Archived::Signature::TIMESTAMPS.each do |timestamp, column|
      context "when the email sent timestamp for '#{timestamp}' is not set" do
        subject(:signatures) { described_class.need_emailing_for(timestamp, since: requested_at) }

        it "includes subscribed signatures" do
          expect(signatures).to match_array([creator, subscribed])
        end

        it "does not include unsubscribed signatures" do
          expect(signatures).not_to include(unsubscribed)
        end

        it "does not include pending signatures" do
          expect(signatures).not_to include(pending)
        end

        it "does not include fraudulent signatures" do
          expect(signatures).not_to include(fraudulent)
        end

        it "does not include invalidated signatures" do
          expect(signatures).not_to include(invalidated)
        end
      end

      context "when the email sent timestamp for '#{column}' is set to before the requested timestamp" do
        subject(:signatures) { described_class.need_emailing_for(timestamp, since: requested_at) }

        before do
          subscribed.update_column(column, requested_at - 1.day)
        end

        it "includes the signature" do
          expect(signatures).to include(subscribed)
        end
      end

      context "when the email sent timestamp for '#{column}' is set to the same as the requested timestamp" do
        subject(:signatures) { described_class.need_emailing_for(timestamp, since: requested_at) }

        before do
          subscribed.update_column(column, requested_at)
        end

        it "does not include the signature" do
          expect(signatures).not_to include(subscribed)
        end
      end

      context "when the email sent timestamp for '#{column}' is set to after as the requested timestamp" do
        subject(:signatures) { described_class.need_emailing_for(timestamp, since: requested_at) }

        before do
          subscribed.update_column(column, requested_at + 1.day)
        end

        it "does not include the signature" do
          expect(signatures).not_to include(subscribed)
        end
      end

      context "when there is an additional scope" do
        let!(:coventry_signature) { FactoryBot.create(:archived_signature, :validated, constituency_id: "3427") }
        let!(:romford_signature) { FactoryBot.create(:archived_signature, :validated, constituency_id: "3703") }

        subject(:signatures) { described_class.need_emailing_for(timestamp, since: requested_at, scope: { constituency_id: "3427" }) }

        it "returns signatures within the scope" do
          expect(subject).to include coventry_signature
        end

        it "does not return signatures outside the scope" do
          expect(subject).not_to include romford_signature
        end
      end
    end
  end

  describe ".search" do
    let(:scope) { double(:scope) }

    context "when searching with an ip address" do
      it "calls the for_ip scope and paginates the result" do
        expect(Archived::Signature).to receive(:for_ip).with("127.0.0.1").and_return(scope)
        expect(scope).to receive(:paginate).with(page: 1, per_page: 50)
        described_class.search("127.0.0.1")
      end

      context "and passing the page parameter" do
        it "calls the for_ip scope and paginates the result" do
          expect(Archived::Signature).to receive(:for_ip).with("127.0.0.1").and_return(scope)
          expect(scope).to receive(:paginate).with(page: 2, per_page: 50)
          described_class.search("127.0.0.1", page: "2")
        end
      end
    end

    context "when searching with a domain" do
      it "calls the for_domain scope and paginates the result" do
        expect(Archived::Signature).to receive(:for_domain).with("@example.com").and_return(scope)
        expect(scope).to receive(:paginate).with(page: 1, per_page: 50)
        described_class.search("@example.com")
      end

      context "and passing the page parameter" do
        it "calls the for_ip scope and paginates the result" do
          expect(Archived::Signature).to receive(:for_domain).with("@example.com").and_return(scope)
          expect(scope).to receive(:paginate).with(page: 2, per_page: 50)
          described_class.search("@example.com", page: "2")
        end
      end
    end

    context "when searching with an email address" do
      it "calls the for_email scope and paginates the result" do
        expect(Archived::Signature).to receive(:for_email).with("alice@example.com").and_return(scope)
        expect(scope).to receive(:paginate).with(page: 1, per_page: 50)
        described_class.search("alice@example.com")
      end

      context "and passing the page parameter" do
        it "calls the for_email scope and paginates the result" do
          expect(Archived::Signature).to receive(:for_email).with("alice@example.com").and_return(scope)
          expect(scope).to receive(:paginate).with(page: 2, per_page: 50)
          described_class.search("alice@example.com", page: "2")
        end
      end
    end

    context "when searching with a name" do
      it "calls the for_name scope and paginates the result" do
        expect(Archived::Signature).to receive(:for_name).with("Alice").and_return(scope)
        expect(scope).to receive(:paginate).with(page: 1, per_page: 50)
        described_class.search("Alice")
      end

      context "and passing the page parameter" do
        it "calls the for_name scope and paginates the result" do
          expect(Archived::Signature).to receive(:for_name).with("Alice").and_return(scope)
          expect(scope).to receive(:paginate).with(page: 2, per_page: 50)
          described_class.search("Alice", page: "2")
        end
      end
    end
  end

  describe ".subscribe!" do
    let(:creator) { FactoryBot.build(:archived_signature, creator: true) }
    let(:petition) { FactoryBot.create(:archived_petition, creator: creator, signature_count: 6) }

    before do
      5.times do
        FactoryBot.create(:archived_signature, petition: petition, notify_by_email: false)
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
      let(:signature) { FactoryBot.create(:archived_signature, :pending, petition: petition) }

      it "doesn't raise an error" do
        expect {
          described_class.subscribe!([signature.id])
        }.not_to raise_error
      end
    end

    context "with a pending signature that isn't subscribed" do
      let(:signature) { FactoryBot.create(:archived_signature, :pending, petition: petition, notify_by_email: false) }

      it "subscribes the signature" do
        expect {
          described_class.subscribe!([signature.id])
        }.to change {
          signature.reload.unsubscribed?
        }.from(true).to(false)
      end
    end

    context "with a validated signature" do
      let(:signature) { FactoryBot.create(:archived_signature, :validated, petition: petition, notify_by_email: false) }

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
    let(:creator) { FactoryBot.build(:archived_signature, creator: true) }
    let(:petition) { FactoryBot.create(:archived_petition, creator: creator, signature_count: 6) }

    before do
      5.times do
        FactoryBot.create(:archived_signature, petition: petition, notify_by_email: true)
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
        }.to raise_error(RuntimeError, "Can’t unsubscribe the creator signature")
      end
    end

    context "with a pending signature" do
      let(:signature) { FactoryBot.create(:archived_signature, :pending, petition: petition, notify_by_email: true) }

      it "raises an error" do
        expect {
          described_class.unsubscribe!([signature.id])
        }.to raise_error(RuntimeError, "Can’t unsubscribe a pending signature")
      end
    end

    context "with a validated signature" do
      let(:signature) { FactoryBot.create(:archived_signature, :validated, petition: petition, notify_by_email: true) }

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
    let(:creator) { FactoryBot.build(:archived_signature, creator: true) }
    let(:petition) { FactoryBot.create(:archived_petition, creator: creator, signature_count: 6) }
    let(:signature) { petition.signatures.last }

    before do
      5.times do
        FactoryBot.create(:archived_signature, petition: petition)
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
      it "destroys the signature" do
        expect {
          described_class.destroy!([signature.id])
        }.to change {
          petition.reload.signatures.count
        }.from(6).to(5)
      end

      it "doesn't decrement the petition signature count" do
        expect {
          described_class.destroy!([signature.id])
        }.not_to change {
          petition.reload.signature_count
        }
      end
    end

    context "when one signature fails" do
      let(:signatures) { [signature, creator] }
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

  describe '#get_email_sent_at_for' do
    let(:signature) { FactoryBot.create(:archived_signature) }
    let(:sent_at) { 6.days.ago }

    Archived::Signature::TIMESTAMPS.each do |timestamp, column|
      context "when the email sent timestamp for '#{timestamp}' is not set" do
        it "returns nil" do
          expect(signature.get_email_sent_at_for(timestamp)).to be_nil
        end
      end

      context "when the email sent timestamp for '#{timestamp}' is set" do
        before do
          signature.update_column(column, sent_at)
        end

        it "returns the stored timestamp" do
          expect(signature.get_email_sent_at_for(timestamp)).to be_usec_precise_with(sent_at)
        end
      end
    end
  end

  describe '#set_email_sent_at_for' do
    let(:signature) { FactoryBot.create(:archived_signature) }
    let(:sent_at) { 6.days.ago }

    Archived::Signature::TIMESTAMPS.each do |timestamp, column|
      context "when a time is supplied for the email sent timestamp '#{timestamp}'" do
        it "sets the column to the supplied time" do
          expect {
            signature.set_email_sent_at_for(timestamp, to: sent_at)
          }.to change {
            signature.reload[column]
          }.from(nil).to(be_usec_precise_with(sent_at))
        end
      end

      context "when a time is not supplied for the email sent timestamp '#{timestamp}'" do
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

  describe "#pending?" do
    context "when the signature has a state of 'pending'" do
      let(:signature) { FactoryBot.build(:archived_signature, state: "pending") }

      it "returns true" do
        expect(signature.pending?).to be_truthy
      end
    end

    (Archived::Signature::STATES - [Archived::Signature::PENDING_STATE]).each do |state|
      context "when the signature has a state of '#{state}'" do
        let(:signature) { FactoryBot.build(:archived_signature, state: state) }

        it "returns false" do
          expect(signature.pending?).to be_falsey
        end
      end
    end
  end

  describe "#fraudulent?" do
    context "when the signature has a state of 'fraudulent'" do
      let(:signature) { FactoryBot.build(:archived_signature, state: "fraudulent") }

      it "returns true" do
        expect(signature.fraudulent?).to be_truthy
      end
    end

    (Archived::Signature::STATES - [Archived::Signature::FRAUDULENT_STATE]).each do |state|
      context "when the signature has a state of '#{state}'" do
        let(:signature) { FactoryBot.build(:archived_signature, state: state) }

        it "returns false" do
          expect(signature.fraudulent?).to be_falsey
        end
      end
    end
  end

  describe "#validated?" do
    context "when the signature has a state of 'validated'" do
      let(:signature) { FactoryBot.build(:archived_signature, state: "validated") }

      it "returns true" do
        expect(signature.validated?).to be_truthy
      end
    end

    (Archived::Signature::STATES - [Archived::Signature::VALIDATED_STATE]).each do |state|
      context "when the signature has a state of '#{state}'" do
        let(:signature) { FactoryBot.build(:archived_signature, state: state) }

        it "returns false" do
          expect(signature.validated?).to be_falsey
        end
      end
    end
  end

  describe "#invalidated?" do
    context "when the signature has a state of 'invalidated'" do
      let(:signature) { FactoryBot.build(:archived_signature, state: "invalidated") }

      it "returns true" do
        expect(signature.invalidated?).to be_truthy
      end
    end

    (Archived::Signature::STATES - [Archived::Signature::INVALIDATED_STATE]).each do |state|
      context "when the signature has a state of '#{state}'" do
        let(:signature) { FactoryBot.build(:archived_signature, state: state) }

        it "returns false" do
          expect(signature.invalidated?).to be_falsey
        end
      end
    end
  end

  describe "#subscribed?" do
    context "when the signature is pending" do
      let(:signature) { FactoryBot.build(:archived_signature, :pending, notify_by_email: true) }

      it "returns false" do
        expect(signature.subscribed?).to eq(false)
      end
    end

    context "when the signature is validated" do
      context "and notify_by_email is true" do
        let(:signature) { FactoryBot.build(:archived_signature, :validated, notify_by_email: true) }

        it "returns true" do
          expect(signature.subscribed?).to eq(true)
        end
      end

      context "and notify_by_email is false" do
        let(:signature) { FactoryBot.build(:archived_signature, :validated, notify_by_email: false) }

        it "returns false" do
          expect(signature.subscribed?).to eq(false)
        end
      end
    end

    context "when the signature is fraudulent" do
      let(:signature) { FactoryBot.build(:archived_signature, :fraudulent, notify_by_email: true) }

      it "returns false" do
        expect(signature.subscribed?).to eq(false)
      end
    end

    context "when the signature is invalidated" do
      let(:signature) { FactoryBot.build(:archived_signature, :invalidated, notify_by_email: true) }

      it "returns false" do
        expect(signature.subscribed?).to eq(false)
      end
    end
  end

  describe "#unsubscribed?" do
    context "when notify_by_email is true" do
      let(:signature) { FactoryBot.build(:archived_signature, notify_by_email: true) }

      it "returns false" do
        expect(signature.unsubscribed?).to be_falsey
      end
    end

    context "when notify_by_email is false" do
      let(:signature) { FactoryBot.build(:archived_signature, notify_by_email: false) }

      it "returns true" do
        expect(signature.unsubscribed?).to be_truthy
      end
    end
  end

  describe "#unsubscribe!" do
    let(:signature) { FactoryBot.create(:archived_signature, notify_by_email: subscribed) }
    let(:unsubscribe_token) { signature.unsubscribe_token }

    context "when subcribed" do
      let(:subscribed) { true }

      it "changes the subscription status" do
        expect {
          signature.unsubscribe!(unsubscribe_token)
        }.to change {
          signature.notify_by_email
        }.from(true).to(false)
      end

      it "doesn't add an error to the :base attribute" do
        expect {
          signature.unsubscribe!(unsubscribe_token)
        }.not_to change {
          signature.errors[:base]
        }
      end
    end

    context "when already unsubcribed" do
      let(:subscribed) { false }

      it "doesn't change the subscription status" do
        expect {
          signature.unsubscribe!(unsubscribe_token)
        }.not_to change {
          signature.notify_by_email
        }
      end

      it "adds an error to the :base attribute" do
        expect {
          signature.unsubscribe!(unsubscribe_token)
        }.to change {
          signature.errors[:base]
        }.from([]).to(["Already Unsubscribed"])
      end
    end

    context "when token is invalid" do
      let(:subscribed) { true }
      let(:unsubscribe_token) { "invalid token" }

      it "doesn't change the subscription status" do
        expect {
          signature.unsubscribe!(unsubscribe_token)
        }.not_to change {
          signature.notify_by_email
        }
      end

      it "adds an error to the :base attribute" do
        expect {
          signature.unsubscribe!(unsubscribe_token)
        }.to change {
          signature.errors[:base]
        }.from([]).to(["Invalid Unsubscribe Token"])
      end
    end
  end

  describe "#already_unsubscribed?" do
    let(:signature) { FactoryBot.create(:archived_signature) }

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
    let(:signature) { FactoryBot.create(:archived_signature) }

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

  describe "#anonymized?" do
    context "when anonymized_at is nil" do
      let(:signature) { FactoryBot.build(:archived_signature, anonymized_at: nil) }

      it "return false" do
        expect(signature.anonymized?).to eq(false)
      end
    end

    context "when anonymized_at is not nil" do
      let(:signature) { FactoryBot.build(:archived_signature, anonymized_at: 1.week.ago) }

      it "return true" do
        expect(signature.anonymized?).to eq(true)
      end
    end
  end

  describe "#anonymize!" do
    let!(:timestamp) { Time.current.beginning_of_day }

    it "anonymizes the name" do
      signature = FactoryBot.create(:archived_signature, name: "Jo Public")

      expect {
        signature.anonymize!(timestamp)
      }.to change {
        signature.reload.name
      }.from("Jo Public").to("Signature #{signature.id}")
    end

    it "anonymizes the email" do
      signature = FactoryBot.create(:archived_signature, email: "jo.public@gmail.com")

      expect {
        signature.anonymize!(timestamp)
      }.to change {
        signature.reload.email
      }.from("jo.public@gmail.com").to("signature-#{signature.id}@example.com")
    end

    it "anonymizes the ip address" do
      signature = FactoryBot.create(:archived_signature, ip_address: "12.34.56.78")

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
      signature = FactoryBot.create(:archived_signature, postcode: "CV66PS", constituency_id: "3427")

      expect {
        signature.anonymize!(timestamp)
      }.to change {
        signature.reload.postcode
      }.from("CV66PS").to("CV21HN")
    end

    context "when the constituency is missing" do
      context "and the signature is in the UK" do
        it "sets the postcode to ZZ993WZ" do
          signature = FactoryBot.create(:archived_signature, postcode: "SW1A1AA", location_code: "GB", constituency_id: nil)

          expect {
            signature.anonymize!(timestamp)
          }.to change {
            signature.reload.postcode
          }.from("SW1A1AA").to("ZZ993WZ")
        end
      end

      context "and the signature is not in the UK" do
        it "sets the postcode to nil" do
          signature = FactoryBot.create(:archived_signature, postcode: "12345", location_code: "US", constituency_id: nil)

          expect {
            signature.anonymize!(timestamp)
          }.to change {
            signature.reload.postcode
          }.from("12345").to(nil)
        end
      end
    end
  end
end
