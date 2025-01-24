require 'rails_helper'

RSpec.describe Page, type: :model do
  subject { FactoryBot.build(:page) }

  describe "schema" do
    it { is_expected.to have_db_column(:slug).of_type(:string).with_options(limit: 100, null: false) }
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(limit: 100, null: false) }
    it { is_expected.to have_db_column(:content).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:slug]).unique }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:content) }

    it { is_expected.to validate_uniqueness_of(:slug) }

    it { is_expected.to validate_length_of(:slug).is_at_most(100) }
    it { is_expected.to validate_length_of(:title).is_at_most(100) }

    it { is_expected.to allow_value("slug").for(:slug) }
    it { is_expected.to allow_value("this-is-a-slug").for(:slug) }
    it { is_expected.not_to allow_value("SLUG").for(:slug) }
    it { is_expected.not_to allow_value("this_is_a_slug").for(:slug) }
  end

  describe "#to_param" do
    let(:page) { FactoryBot.create(:page, slug: "this-is-a-slug") }

    it "returns the slug" do
      expect(page.to_param).to eq("this-is-a-slug")
    end
  end
end
