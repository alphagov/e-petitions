require 'rails_helper'

RSpec.describe Department, type: :model do
  subject { FactoryBot.build(:department) }

  describe "schema" do
    it { is_expected.to have_db_column(:external_id).of_type(:string).with_options(limit: 30) }
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(limit: 100, null: false) }
    it { is_expected.to have_db_column(:acronym).of_type(:string).with_options(limit: 10) }
    it { is_expected.to have_db_column(:url).of_type(:string).with_options(limit: 100) }
    it { is_expected.to have_db_column(:start_date).of_type(:date) }
    it { is_expected.to have_db_column(:end_date).of_type(:date) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "validations" do
    it { is_expected.to validate_length_of(:external_id).is_at_most(30) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:acronym).is_at_most(10) }
    it { is_expected.to validate_length_of(:url).is_at_most(100) }
  end

  describe "callbacks" do
    context "when a department is destroyed" do
      let!(:department) { FactoryBot.create(:department) }
      let!(:petition) { FactoryBot.create(:petition, departments: [department.id]) }
      let!(:archived_petition) { FactoryBot.create(:archived_petition, departments: [department.id]) }

      it "removes departments from petitions" do
        expect {
          department.destroy
        }.to change {
          petition.reload.departments
        }.from([department.id]).to([])
      end

      it "removes departments from archived petitions" do
        expect {
          department.destroy
        }.to change {
          archived_petition.reload.departments
        }.from([department.id]).to([])
      end
    end
  end

  describe ".by_name" do
    let!(:department_1) { FactoryBot.create(:department, name: "baz") }
    let!(:department_2) { FactoryBot.create(:department, name: "foo") }
    let!(:department_3) { FactoryBot.create(:department, name: "bar") }

    it "returns departments in alphabetical order" do
      expect(described_class.by_name).to match_array([department_3, department_1, department_2])
    end
  end
end
