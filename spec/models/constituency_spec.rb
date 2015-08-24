require 'rails_helper'

RSpec.describe Constituency, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:constituency)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:slug).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:external_id).of_type(:string).with_options(null: false, limit: 30) }
    it { is_expected.to have_db_column(:ons_code).of_type(:string).with_options(null: false, limit: 10) }
    it { is_expected.to have_db_column(:mp_id).of_type(:string).with_options(null: true, limit: 30) }
    it { is_expected.to have_db_column(:mp_name).of_type(:string).with_options(null: true, limit: 100) }
    it { is_expected.to have_db_column(:mp_date).of_type(:date).with_options(null: true) }
  end

  describe "associations" do
    it { is_expected.to have_many(:signatures) }
    it { is_expected.to have_many(:petitions).through(:signatures) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:slug]).unique }
    it { is_expected.to have_db_index([:external_id]).unique }
  end

  describe "validations" do
    subject { FactoryGirl.build(:constituency) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }

    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_length_of(:external_id).is_at_most(30) }

    it { is_expected.to validate_presence_of(:ons_code) }
    it { is_expected.not_to allow_value("E1").for(:ons_code) }
    it { is_expected.not_to allow_value("J00000001").for(:ons_code) }

    %w[E W S N].each do |country|
      it { is_expected.to allow_value("%s%08d" % [country, 1]).for(:ons_code) }
    end

    it { is_expected.not_to validate_presence_of(:mp_id) }
    it { is_expected.to validate_length_of(:mp_id).is_at_most(30) }

    it { is_expected.not_to validate_presence_of(:mp_name) }
    it { is_expected.to validate_length_of(:mp_name).is_at_most(100) }

    it { is_expected.not_to validate_presence_of(:mp_date) }
  end

  describe "callbacks" do
    describe "slug" do
      context "when creating a constituency" do
        let!(:constituency) { FactoryGirl.create(:constituency, name: "Coventry North East") }

        it "is generated from the name" do
          expect(constituency.slug).to eq("coventry-north-east")
        end
      end

      context "when updated a constituency" do
        let!(:constituency) { FactoryGirl.create(:constituency, name: "Coventry North East") }

        before do
          constituency.update!(name: "Coventry North")
        end

        it "is regenerated from the name" do
          expect(constituency.slug).to eq("coventry-north")
        end
      end
    end
  end

  describe ".find_by_postcode" do
    context "when the constituency doesn't exist in the database" do
      before do
        stub_api_request_for("N11TY").to_return(api_response(:ok, "single"))
      end

      it "saves the constituency to the database" do
        constituency = Constituency.find_by_postcode("N11TY")
        expect(constituency.persisted?).to be_truthy
      end
    end

    context "when the constituency already exists in the database" do
      let!(:existing_constituency) do
        FactoryGirl.create(:constituency, {
          name: "Islington South and Finsbury", external_id: "3550", ons_code: "E14000764",
          mp_id: "1536", mp_name: "Emily Thornberry MP", mp_date: "2015-05-07T00:00:00"
        })
      end

      before do
        stub_api_request_for("N11TY").to_return(api_response(:ok, "single"))
      end

      it "returns the existing record" do
        constituency = Constituency.find_by_postcode("N11TY")
        expect(constituency).to eq(existing_constituency)
      end
    end

    context "when the API returns no results" do
      before do
        stub_api_request_for("N11TY").to_return(api_response(:not_acceptable))
      end

      it "returns nil" do
        constituency = Constituency.find_by_postcode("N11TY")
        expect(constituency).to be_nil
      end
    end
  end

  describe "#mp_url" do
    let(:constituency) { FactoryGirl.build(:constituency, mp_id: "2564", mp_name: "The Rt. Hon. Duncan Short MP") }

    it "generates a valid link to the MP on the parliament.uk website" do
      expect(constituency.mp_url).to eq <<-URL.strip
        http://www.parliament.uk/biographies/commons/the-rt-hon-duncan-short-mp/2564
      URL
    end
  end
end
