require 'rails_helper'

RSpec.describe ConstituencyPetitionJournal, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:constituency_petition_journal)).to be_valid
  end

  describe "defaults" do
    it "has 0 for initial signature_count" do
      expect(subject.signature_count).to eq 0
    end
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id, :constituency_id]).unique }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:constituency_id) }
    it { is_expected.to validate_length_of(:constituency_id).is_at_most(255) }
    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_presence_of(:signature_count) }
  end

  describe ".for" do
    let(:petition) { FactoryBot.create(:petition) }
    let(:constituency_id) { FactoryBot.generate(:constituency_id) }

    context "when there is a journal for the requested petition and constituency" do
      let!(:existing_record) { FactoryBot.create(:constituency_petition_journal, petition: petition, constituency_id: constituency_id, signature_count: 30) }

      it "doesn't create a new record" do
        expect {
          described_class.for(petition, constituency_id)
        }.not_to change(described_class, :count)
      end

      it "fetches the instance from the DB" do
        fetched = described_class.for(petition, constituency_id)
        expect(fetched).to eq(existing_record)
      end
    end

    context "when there is no journal for the requested petition and constituency" do
      let!(:journal) { described_class.for(petition, constituency_id) }

      it "returns a newly created instance" do
        expect(journal).to be_an_instance_of(described_class)
      end

      it "persists the new instance in the DB" do
        expect(journal).to be_persisted
      end

      it "sets the petition of the new instance to the supplied petition" do
        expect(journal.petition).to eq(petition)
      end

      it "sets the constituency_id of the new instance to the supplied constituency_id" do
        expect(journal.constituency_id).to eq(constituency_id)
      end

      it "has 0 for a signature count" do
        expect(journal.signature_count).to eq(0)
      end
    end
  end

  describe ".invalidate_signature_for" do
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:constituency_id) { FactoryBot.generate(:constituency_id) }
    let!(:journal) { FactoryBot.create(:constituency_petition_journal, petition: petition, constituency_id: constituency_id, signature_count: signature_count) }
    let(:signature_count) { 1 }

    context "when the supplied signature is valid" do
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition, constituency_id: constituency_id) }
      let(:now) { 1.hour.from_now.change(usec: 0) }

      it "decrements the signature_count by 1" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.to change { journal.reload.signature_count }.by(-1)
      end

      it "updates the updated_at timestamp" do
        expect {
          described_class.invalidate_signature_for(signature, now)
        }.to change { journal.reload.updated_at }.to(now)
      end
    end

    context "when the supplied signature is nil" do
      let(:signature) { nil }

      it "does nothing" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.not_to change { journal.reload.signature_count }
      end
    end

    context "when the supplied signature has no country" do
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition, constituency_id: nil) }

      it "does nothing" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.not_to change { journal.reload.signature_count }
      end
    end

    context "when the supplied signature is not validated" do
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, constituency_id: constituency_id) }

      it "does nothing" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.not_to change { journal.reload.signature_count }
      end
    end

    context "when the signature count is already zero" do
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition, constituency_id: constituency_id) }
      let(:signature_count) { 0 }

      it "does nothing" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.not_to change { journal.reload.signature_count }
      end
    end

    context "when no journal exists" do
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition, constituency_id: constituency_id) }

      before do
        described_class.delete_all
      end

      it "creates a new journal" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.to change(described_class, :count).by(1)
      end
    end
  end

  describe ".increment_signature_counts_for" do
    let(:constituency_1) { FactoryBot.generate(:constituency_id) }
    let(:constituency_2) { FactoryBot.generate(:constituency_id) }
    let!(:petition) { FactoryBot.create(:open_petition, creator_attributes: { constituency_id: constituency_1 }) }

    let(:journal_1) { described_class.for(petition, constituency_1) }
    let(:journal_2) { described_class.for(petition, constituency_2) }

    before do
      FactoryBot.create(:validated_signature, petition: petition, constituency_id: constituency_1)
      FactoryBot.create(:validated_signature, petition: petition, constituency_id: constituency_2)

      described_class.reset_signature_counts_for(petition)
    end

    it "increments all of the journals" do
      expect(journal_1.signature_count).to eq(2)
      expect(journal_2.signature_count).to eq(1)

      FactoryBot.create(:validated_signature, petition: petition, constituency_id: constituency_1, increment: false)
      FactoryBot.create(:validated_signature, petition: petition, constituency_id: constituency_2, increment: false)

      last_signed_at = petition.last_signed_at
      petition.increment_signature_count!

      described_class.increment_signature_counts_for(petition, last_signed_at)

      expect(journal_1.reload.signature_count).to eq(3)
      expect(journal_2.reload.signature_count).to eq(2)
    end
  end

  describe ".reset_signature_counts_for" do
    let(:petition_1) { FactoryBot.create(:open_petition, creator_attributes: { constituency_id: constituency_1, validated_at: 5.minutes.ago }) }
    let(:constituency_1) { FactoryBot.generate(:constituency_id) }
    let(:petition_2) { FactoryBot.create(:open_petition, creator_attributes: { constituency_id: constituency_1, validated_at: 5.minutes.ago }) }
    let(:constituency_2) { FactoryBot.generate(:constituency_id) }

    before do
      described_class.for(petition_1, constituency_1).update_columns(signature_count: 20, last_signed_at: 5.minutes.ago)
      described_class.for(petition_1, constituency_2).update_columns(signature_count: 10, last_signed_at: nil)
      described_class.for(petition_2, constituency_1).update_columns(signature_count: 1, last_signed_at: 5.minutes.ago)
      described_class.for(petition_2, constituency_2).update_columns(signature_count: 1, last_signed_at: nil)
    end

    context 'when there are no signatures' do
      it 'resets all the counts to 0 or 1 for the creator' do
        described_class.reset_signature_counts_for(petition_1)
        described_class.reset_signature_counts_for(petition_2)

        expect(described_class.for(petition_1, constituency_1).signature_count).to eq 1
        expect(described_class.for(petition_1, constituency_2).signature_count).to eq 0
        expect(described_class.for(petition_2, constituency_1).signature_count).to eq 1
        expect(described_class.for(petition_2, constituency_2).signature_count).to eq 0
      end
    end

    context 'when there are signatures' do
      before do
        4.times { FactoryBot.create(:validated_signature, petition: petition_1, constituency_id: constituency_1, validated_at: 1.minute.ago) }
        2.times { FactoryBot.create(:pending_signature, petition: petition_1, constituency_id: constituency_1) }
        3.times { FactoryBot.create(:validated_signature, petition: petition_1, constituency_id: constituency_2, validated_at: 1.minute.ago) }
        2.times { FactoryBot.create(:validated_signature, petition: petition_2, constituency_id: constituency_1, validated_at: 1.minute.ago) }
        5.times { FactoryBot.create(:pending_signature, petition: petition_2, constituency_id: constituency_2) }
      end

      it 'resets the counts to that of the validated signatures for the petition and country' do
        described_class.reset_signature_counts_for(petition_1)
        described_class.reset_signature_counts_for(petition_2)

        expect(described_class.for(petition_1, constituency_1).signature_count).to eq 5 # +1 for the creator
        expect(described_class.for(petition_1, constituency_2).signature_count).to eq 3
        expect(described_class.for(petition_2, constituency_1).signature_count).to eq 3 # +1 for the creator
        expect(described_class.for(petition_2, constituency_2).signature_count).to eq 0
      end

      it 'does not attempt to journal signatures without constituencies' do
        FactoryBot.create(:validated_signature, petition: petition_1, constituency_id: nil)

        expect {
          described_class.reset_signature_counts_for(petition_1)
          described_class.reset_signature_counts_for(petition_2)
        }.not_to raise_error

        expect(described_class.find_by(petition: petition_1, constituency_id: nil)).to be_nil
      end
    end
  end
end
