require 'rails_helper'

RSpec.describe ConstituencyPetitionJournal, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:constituency_petition_journal)).to be_valid
  end

  describe "defaults" do
    subject { described_class.new }
    it "has 0 for initial signature_count" do
      expect(subject.signature_count).to eq 0
    end
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id, :constituency_id]).unique }
  end

  describe "validations" do
    subject { FactoryGirl.build(:constituency_petition_journal) }

    it { is_expected.to validate_presence_of(:constituency_id) }
    it { is_expected.to validate_length_of(:constituency_id).is_at_most(255) }
    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_uniqueness_of(:constituency_id).scoped_to(:petition_id) }
    it { is_expected.to validate_presence_of(:signature_count) }
  end

  describe ".for" do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:constituency_id) { FactoryGirl.generate(:constituency_id) }

    context "when there is a journal for the requested petition and constituency" do
      let!(:existing_record) { FactoryGirl.create(:constituency_petition_journal, petition: petition, constituency_id: constituency_id, signature_count: 30) }

      it "doesn't create a new record" do
        expect {
          described_class.for(petition, constituency_id)
        }.not_to change(described_class, :count)
      end

      it "fetches the instance from the DB" do
        fetched = described_class.for(petition, constituency_id)
        expect(fetched).to eq existing_record
      end
    end

    context "when there is no journal for the requested petition and constituency" do
      it "returns the newly initialized instance" do
        fetched = described_class.for(petition, constituency_id)
        expect(fetched).to be_a described_class
      end

      it "persists the new instance in the DB" do
        expect {
          described_class.for(petition, constituency_id)
        }.to change(described_class, :count).by(1)
      end

      it "sets the petition of the new instance to the supplied petition" do
        fetched = described_class.for(petition, constituency_id)
        expect(fetched.petition).to eq petition
      end

      it "sets the constituency_id of the new instance to the supplied petition" do
        fetched = described_class.for(petition, constituency_id)
        expect(fetched.constituency_id).to eq constituency_id
      end

      it "has 0 for a signature count" do
        fetched = described_class.for(petition, constituency_id)
        expect(fetched.signature_count).to eq 0
      end
    end
  end

  describe "#record_new_signature" do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:constituency_id) { FactoryGirl.generate(:constituency_id) }

    subject { described_class.for(petition, constituency_id) }

    context 'on a saved instance' do
      before { subject.update_attribute(:signature_count, 20) }

      it "increments signature_count by 1" do
        expect {
          subject.record_new_signature
        }.to change(subject, :signature_count).by(1)
      end

      it "persists the change" do
        old_signature_count = subject.signature_count
        subject.record_new_signature
        subject.reload
        expect(subject.signature_count).not_to eq old_signature_count
      end

      it "increments the signature_count in the DB properly" do
        first_signature_count = subject.signature_count
        other_copy = described_class.for(petition, constituency_id)
        other_copy.record_new_signature
        second_signature_count = other_copy.reload.signature_count
        subject.record_new_signature
        expect(subject.signature_count).to eq(second_signature_count)
        expect(subject.reload.signature_count).to eq(second_signature_count + 1)
      end

      it 'only executes the update SQL query' do
        expect {
          subject.record_new_signature
        }.not_to exceed_query_limit(1)
      end
    end

    context 'on a new instance' do
      it "sets the signature_count to 1" do
        subject.record_new_signature
        expect(subject.signature_count).to eq 1
      end

      it "saves the instance to the DB" do
        subject.record_new_signature
        expect(subject).to be_persisted
      end
    end
  end

  describe ".record_new_signature_for" do
    let(:petition) { FactoryGirl.create(:open_petition) }
    let(:constituency_id) { FactoryGirl.generate(:constituency_id) }
    let(:signature) { FactoryGirl.build(:validated_signature, petition: petition, constituency_id: constituency_id) }

    it "does nothing if the supplied signature is nil" do
      expect {
        described_class.record_new_signature_for(nil)
      }.not_to change(described_class, :count)
    end

    it "does nothing if the supplied signature has no petition" do
      signature.petition = nil
      expect {
        described_class.record_new_signature_for(signature)
      }.not_to change(described_class, :count)
    end

    it "does nothing if the supplied signature has no constituency_id" do
      signature.constituency_id = nil
      expect {
        described_class.record_new_signature_for(signature)
      }.not_to change(described_class, :count)
    end

    it "does nothing if the supplied signature is not validated?" do
      signature.state = Signature::PENDING_STATE
      expect {
        described_class.record_new_signature_for(signature)
      }.not_to change(described_class, :count)
    end

    it "creates a new instance and sets the count to 1 if nothing exists already" do
      expect {
        described_class.record_new_signature_for(signature)
      }.to change(described_class, :count).by(1)
      expect(described_class.for(petition, constituency_id).signature_count).to eq 1
    end

    it "increments the signature_count of the existing instance by 1" do
      existing = described_class.for(signature.petition, signature.constituency_id)
      existing.update_attribute(:signature_count, 20)

      described_class.record_new_signature_for(signature)

      existing.reload
      expect(existing.signature_count).to eq 21
    end
  end

  describe ".reset!" do
    let(:petition_1) { FactoryGirl.create(:petition, creator_signature_attributes: {constituency_id: constituency_1}) }
    let(:constituency_1) { FactoryGirl.generate(:constituency_id) }
    let(:petition_2) { FactoryGirl.create(:petition, creator_signature_attributes: {constituency_id: constituency_1}) }
    let(:constituency_2) { FactoryGirl.generate(:constituency_id) }

    before do
      described_class.for(petition_1, constituency_1).update_attribute(:signature_count, 20)
      described_class.for(petition_1, constituency_2).update_attribute(:signature_count, 10)
      described_class.for(petition_2, constituency_2).update_attribute(:signature_count, 1)
    end

    context 'when there are no signatures' do
      it 'resets all the counts to 0 or 1 for the creator' do
        described_class.reset!
        expect(described_class.for(petition_1, constituency_1).signature_count).to eq 1
        expect(described_class.for(petition_1, constituency_2).signature_count).to eq 0
        expect(described_class.for(petition_2, constituency_1).signature_count).to eq 1
        expect(described_class.for(petition_2, constituency_2).signature_count).to eq 0
      end
    end

    context 'when there are signatures' do
      before do
        4.times { FactoryGirl.create(:validated_signature, petition: petition_1, constituency_id: constituency_1) }
        2.times { FactoryGirl.create(:pending_signature, petition: petition_1, constituency_id: constituency_1) }
        3.times { FactoryGirl.create(:validated_signature, petition: petition_1, constituency_id: constituency_2) }
        2.times { FactoryGirl.create(:validated_signature, petition: petition_2, constituency_id: constituency_1) }
        5.times { FactoryGirl.create(:pending_signature, petition: petition_2, constituency_id: constituency_2) }
      end

      it 'resets the counts to that of the validated signatures for the petition and country' do
        described_class.reset!
        expect(described_class.for(petition_1, constituency_1).signature_count).to eq 5 # +1 for the creator
        expect(described_class.for(petition_1, constituency_2).signature_count).to eq 3
        expect(described_class.for(petition_2, constituency_1).signature_count).to eq 3 # +1 for the creator
        expect(described_class.for(petition_2, constituency_2).signature_count).to eq 0
      end
    end
  end
end
