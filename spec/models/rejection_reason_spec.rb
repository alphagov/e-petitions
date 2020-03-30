require 'rails_helper'

RSpec.describe RejectionReason, type: :model do
  describe "schema" do
    it { is_expected.to have_db_column(:code).of_type(:string).with_options(limit: 30, null: false) }
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(limit: 100, null: false) }
    it { is_expected.to have_db_column(:description_en).of_type(:string).with_options(limit: 2000, null: false) }
    it { is_expected.to have_db_column(:description_cy).of_type(:string).with_options(limit: 2000, null: false) }
    it { is_expected.to have_db_column(:hidden).of_type(:boolean).with_options(null: false, default: false) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:code]).unique }
    it { is_expected.to have_db_index([:title]).unique }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description_en) }
    it { is_expected.to validate_presence_of(:description_cy) }

    it { is_expected.to validate_uniqueness_of(:code) }
    it { is_expected.to validate_uniqueness_of(:title) }

    it { is_expected.to validate_length_of(:code).is_at_most(30) }
    it { is_expected.to validate_length_of(:title).is_at_most(100) }
    it { is_expected.to validate_length_of(:description_en).is_at_most(1000) }
    it { is_expected.to validate_length_of(:description_cy).is_at_most(1000) }

    it { is_expected.to allow_value("code").for(:code) }
    it { is_expected.to allow_value("rejection-code").for(:code) }
    it { is_expected.not_to allow_value("CODE").for(:code) }
    it { is_expected.not_to allow_value("rejection_code").for(:code) }
    it { is_expected.not_to allow_value("code-1").for(:code) }
  end

  describe "callbacks" do
    let!(:reason) { FactoryBot.create(:rejection_reason) }

    context "when a reason is used by a petition" do
      let!(:petition) { FactoryBot.create(:rejected_petition, rejection_code: reason.code) }

      it "can't be destroyed" do
        expect {
          reason.destroy
        }.not_to change {
          reason.destroyed?
        }.from(false)
      end
    end

    context "when a reason is not used" do
      let!(:petition) { FactoryBot.create(:rejected_petition) }

      it "can be destroyed" do
        expect {
          reason.destroy
        }.to change {
          reason.destroyed?
        }.from(false).to(true)
      end
    end
  end

  describe ".codes" do
    it "returns a list of all codes" do
      expect(RejectionReason.codes).to eq %w[
        insufficient duplicate irrelevant
        no-action fake-name libellous offensive
        bad-address not-suitable
      ]
    end
  end

  describe ".hidden_codes" do
    it "returns a list of hidden codes" do
      expect(RejectionReason.hidden_codes).to eq %w[
        libellous offensive not-suitable
      ]
    end
  end

  describe "#label" do
    context "when the code is not hidden" do
      let(:reason) { rejection_reasons(:duplicate) }

      it "returns the title" do
        expect(reason.label).to eq("Duplicate petition")
      end
    end

    context "when the code is hidden" do
      let(:reason) { rejection_reasons(:offensive) }

      it "appends (will be hidden) to the title" do
        expect(reason.label).to eq("Offensive, nonsense, joke or advert (will be hidden)")
      end
    end
  end

  describe "#used?" do
    let(:reason) { rejection_reasons(:duplicate) }

    context "when not used by a rejected petition" do
      it "returns false" do
        expect(reason.used?).to eq(false)
      end
    end

    context "when used by a rejected petition" do
      before do
        FactoryBot.create(:rejected_petition, rejection_code: reason.code)
      end

      it "returns true" do
        expect(reason.used?).to eq(true)
      end
    end
  end
end
