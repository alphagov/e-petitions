require 'rails_helper'

RSpec.describe Tag, type: :model do
  subject { FactoryBot.build(:tag) }

  describe "schema" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(limit: 50, null: false) }
    it { is_expected.to have_db_column(:description).of_type(:string).with_options(limit: 200, null: true) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:name]).unique }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(50) }
    it { is_expected.to validate_length_of(:description).is_at_most(200) }
  end

  describe "callbacks" do
    context "when a tag is destroyed" do
      let!(:tag) { FactoryBot.create(:tag) }
      let!(:petition) { FactoryBot.create(:petition, tags: [tag.id]) }

      it "removes tags from petitions" do
        expect {
          tag.destroy
        }.to change {
          petition.reload.tags
        }.from([tag.id]).to([])
      end
    end
  end

  describe ".by_name" do
    let!(:tag_1) { FactoryBot.create(:tag, name: "baz") }
    let!(:tag_2) { FactoryBot.create(:tag, name: "foo") }
    let!(:tag_3) { FactoryBot.create(:tag, name: "bar") }

    it "returns tags in alphabetical order" do
      expect(described_class.by_name).to match_array([tag_3, tag_1, tag_2])
    end
  end
end
