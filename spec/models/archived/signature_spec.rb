require 'rails_helper'

RSpec.describe Archived::Signature, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:archived_signature)).to be_valid
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
    it { is_expected.to have_db_column(:notify_by_email).of_type(:boolean).with_options(default: true) }
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
    it { is_expected.to have_db_column(:uuid).of_type(:uuid) }
    it { is_expected.to have_db_column(:creator).of_type(:boolean).with_options(default: false, null: false) }
    it { is_expected.to have_db_column(:sponsor).of_type(:boolean).with_options(default: false, null: false) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:constituency).with_primary_key(:external_id) }
    it { is_expected.to belong_to(:petition) }
    it { is_expected.to belong_to(:invalidation) }
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
    it { is_expected.to have_db_index([:creator, :petition_id]) }
    it { is_expected.to have_db_index([:sponsor, :petition_id]) }
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


  describe ".need_emailing_for" do
    let!(:petition) { FactoryGirl.create(:archived_petition) }
    let!(:creator) { FactoryGirl.create(:archived_signature, petition: petition, creator: true) }
    let!(:pending) { FactoryGirl.create(:archived_signature, petition: petition, state: "pending") }
    let!(:fraudulent) { FactoryGirl.create(:archived_signature, petition: petition, state: "fraudulent") }
    let!(:invalidated) { FactoryGirl.create(:archived_signature, petition: petition, state: "invalidated") }
    let!(:subscribed) { FactoryGirl.create(:archived_signature, petition: petition) }
    let!(:unsubscribed) { FactoryGirl.create(:archived_signature, petition: petition, notify_by_email: false) }

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
    end
  end

  describe '#get_email_sent_at_for' do
    let(:signature) { FactoryGirl.create(:archived_signature) }
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
    let(:signature) { FactoryGirl.create(:archived_signature) }
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
      let(:signature) { FactoryGirl.build(:archived_signature, state: "pending") }

      it "returns true" do
        expect(signature.pending?).to be_truthy
      end
    end

    (Archived::Signature::STATES - [Archived::Signature::PENDING_STATE]).each do |state|
      context "when the signature has a state of '#{state}'" do
        let(:signature) { FactoryGirl.build(:archived_signature, state: state) }

        it "returns false" do
          expect(signature.pending?).to be_falsey
        end
      end
    end
  end

  describe "#fraudulent?" do
    context "when the signature has a state of 'fraudulent'" do
      let(:signature) { FactoryGirl.build(:archived_signature, state: "fraudulent") }

      it "returns true" do
        expect(signature.fraudulent?).to be_truthy
      end
    end

    (Archived::Signature::STATES - [Archived::Signature::FRAUDULENT_STATE]).each do |state|
      context "when the signature has a state of '#{state}'" do
        let(:signature) { FactoryGirl.build(:archived_signature, state: state) }

        it "returns false" do
          expect(signature.fraudulent?).to be_falsey
        end
      end
    end
  end

  describe "#validated?" do
    context "when the signature has a state of 'validated'" do
      let(:signature) { FactoryGirl.build(:archived_signature, state: "validated") }

      it "returns true" do
        expect(signature.validated?).to be_truthy
      end
    end

    (Archived::Signature::STATES - [Archived::Signature::VALIDATED_STATE]).each do |state|
      context "when the signature has a state of '#{state}'" do
        let(:signature) { FactoryGirl.build(:archived_signature, state: state) }

        it "returns false" do
          expect(signature.validated?).to be_falsey
        end
      end
    end
  end

  describe "#invalidated?" do
    context "when the signature has a state of 'invalidated'" do
      let(:signature) { FactoryGirl.build(:archived_signature, state: "invalidated") }

      it "returns true" do
        expect(signature.invalidated?).to be_truthy
      end
    end

    (Archived::Signature::STATES - [Archived::Signature::INVALIDATED_STATE]).each do |state|
      context "when the signature has a state of '#{state}'" do
        let(:signature) { FactoryGirl.build(:archived_signature, state: state) }

        it "returns false" do
          expect(signature.invalidated?).to be_falsey
        end
      end
    end
  end

  describe "#unsubscribed?" do
    context "when notify_by_email is true" do
      let(:signature) { FactoryGirl.build(:archived_signature, notify_by_email: true) }

      it "returns false" do
        expect(signature.unsubscribed?).to be_falsey
      end
    end

    context "when notify_by_email is false" do
      let(:signature) { FactoryGirl.build(:archived_signature, notify_by_email: false) }

      it "returns true" do
        expect(signature.unsubscribed?).to be_truthy
      end
    end
  end

  describe "#unsubscribe!" do
    let(:signature) { FactoryGirl.create(:archived_signature, notify_by_email: subscribed) }
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
    let(:signature) { FactoryGirl.create(:archived_signature) }

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
    let(:signature) { FactoryGirl.create(:archived_signature) }

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
end
