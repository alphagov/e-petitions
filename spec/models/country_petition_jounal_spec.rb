require 'rails_helper'

RSpec.describe CountryPetitionJournal, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:country_petition_journal)).to be_valid
  end

  describe "defaults" do
    it "has 0 for initial signature_count" do
      expect(subject.signature_count).to eq 0
    end
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id, :country]).unique }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:country) }
    it { is_expected.to validate_length_of(:country).is_at_most(255) }
    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_presence_of(:signature_count) }
  end

  describe ".for" do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:country) { "United Kingdom" }

    context "when there is a journal for the requested petition and country" do
      let!(:existing_record) { FactoryGirl.create(:country_petition_journal, petition: petition, country: country, signature_count: 30) }

      it "doesn't create a new record" do
        expect {
          described_class.for(petition, country)
        }.not_to change(described_class, :count)
      end

      it "fetches the instance from the DB" do
        fetched = described_class.for(petition, country)
        expect(fetched).to eq(existing_record)
      end
    end

    context "when there is no journal for the requested petition and country" do
      let!(:journal) { described_class.for(petition, country) }

      it "returns a newly created instance" do
        expect(journal).to be_an_instance_of(described_class)
      end

      it "persists the new instance in the DB" do
        expect(journal).to be_persisted
      end

      it "sets the petition of the new instance to the supplied petition" do
        expect(journal.petition).to eq(petition)
      end

      it "sets the country of the new instance to the supplied country" do
        expect(journal.country).to eq(country)
      end

      it "has 0 for a signature count" do
        expect(journal.signature_count).to eq(0)
      end
    end
  end

  describe ".record_new_signature_for" do
    let(:petition) { FactoryGirl.create(:open_petition) }
    let(:country) { "United Kingdom" }

    def journal
      described_class.for(petition, country)
    end

    context "when the supplied signature is valid" do
      let(:signature) { FactoryGirl.build(:validated_signature, petition: petition, country: country) }
      let(:now) { 1.hour.from_now.change(usec: 0) }

      it "increments the signature_count by 1" do
        expect {
          described_class.record_new_signature_for(signature)
        }.to change { journal.signature_count }.by(1)
      end

      it "updates the updated_at timestamp" do
        expect {
          described_class.record_new_signature_for(signature, now)
        }.to change { journal.updated_at }.to(now)
      end
    end

    context "when the supplied signature is niL" do
      let(:signature) { nil }

      it "does nothing" do
        expect {
          described_class.record_new_signature_for(signature)
        }.not_to change { journal.signature_count }
      end
    end

    context "when the supplied signature has no petition" do
      let(:signature) { FactoryGirl.build(:validated_signature, petition: nil, country: country) }

      it "does nothing" do
        expect {
          described_class.record_new_signature_for(signature)
        }.not_to change { journal.signature_count }
      end
    end

    context "when the supplied signature has no country" do
      let(:signature) { FactoryGirl.build(:validated_signature, petition: petition, country: nil) }

      it "does nothing" do
        expect {
          described_class.record_new_signature_for(signature)
        }.not_to change { journal.signature_count }
      end
    end

    context "when the supplied signature is not validated" do
      let(:signature) { FactoryGirl.build(:pending_signature, petition: petition, country: country) }

      it "does nothing" do
        expect {
          described_class.record_new_signature_for(signature)
        }.not_to change { journal.signature_count }
      end
    end

    context "when no journal exists" do
      let(:signature) { FactoryGirl.build(:validated_signature, petition: petition, country: country) }

      it "creates a new journal" do
        expect {
          described_class.record_new_signature_for(signature)
        }.to change(described_class, :count).by(1)
      end
    end
  end

  describe ".reset!" do
    let(:petition_1) { FactoryGirl.create(:petition, creator_signature_attributes: {country: country_1}) }
    let(:country_1) { "United Kingdom" }
    let(:petition_2) { FactoryGirl.create(:petition, creator_signature_attributes: {country: country_1}) }
    let(:country_2) { "British Antarctic Territory" }

    before do
      described_class.for(petition_1, country_1).update_attribute(:signature_count, 20)
      described_class.for(petition_1, country_2).update_attribute(:signature_count, 10)
      described_class.for(petition_2, country_2).update_attribute(:signature_count, 1)
    end

    context 'when there are no signatures' do
      it 'resets all the counts to 0 or 1 for the creator' do
        described_class.reset!
        expect(described_class.for(petition_1, country_1).signature_count).to eq 1
        expect(described_class.for(petition_1, country_2).signature_count).to eq 0
        expect(described_class.for(petition_2, country_1).signature_count).to eq 1
        expect(described_class.for(petition_2, country_2).signature_count).to eq 0
      end
    end

    context 'when there are signatures' do
      before do
        4.times { FactoryGirl.create(:validated_signature, petition: petition_1, country: country_1) }
        2.times { FactoryGirl.create(:pending_signature, petition: petition_1, country: country_1) }
        3.times { FactoryGirl.create(:validated_signature, petition: petition_1, country: country_2) }
        2.times { FactoryGirl.create(:validated_signature, petition: petition_2, country: country_1) }
        5.times { FactoryGirl.create(:pending_signature, petition: petition_2, country: country_2) }
      end

      it 'resets the counts to that of the validated signatures for the petition and country' do
        described_class.reset!
        expect(described_class.for(petition_1, country_1).signature_count).to eq 5 # +1 for the creator
        expect(described_class.for(petition_1, country_2).signature_count).to eq 3
        expect(described_class.for(petition_2, country_1).signature_count).to eq 3 # +1 for the creator
        expect(described_class.for(petition_2, country_2).signature_count).to eq 0
      end
    end
  end
end
