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
    it { is_expected.to have_db_column(:example_postcode).of_type(:string).with_options(null: true, limit: 30) }
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

    context "when the API returns updated results" do
      let(:constituency) do
        Constituency.find_by_postcode('OL90LS')
      end

      before do
        FactoryGirl.create(:constituency, {
          name: "Oldham West and Royton", external_id: "3671", ons_code: "E14000871",
          mp_id: "454", mp_name: "Mr Michael Meacher", mp_date: "2015-05-07T00:00:00"
        })

        stub_api_request_for("OL90LS").to_return(api_response(:ok, "updated"))
      end

      it "updates the existing constituency" do
        expect(constituency.mp_name).to eq("Jim McMahon MP")
      end

      it "persists the changes to the database" do
        expect(constituency.reload.mp_name).to eq("Jim McMahon MP")
      end
    end

    context "when the MP has passed away" do
      let(:constituency) do
        Constituency.find_by_postcode('S48AA')
      end

      before do
        FactoryGirl.create(:constituency, {
          name: "Sheffield, Brightside and Hillsborough", external_id: "3724", ons_code: "E14000921",
          mp_id: "4477", mp_name: "Harry Harpham", mp_date: "2015-05-07T00:00:00"
        })

        stub_api_request_for("S48AA").to_return(api_response(:ok, "vacant"))
      end

      it "updates the existing constituency" do
        expect(constituency.mp_name).to eq(nil)
      end

      it "persists the changes to the database" do
        expect(constituency.reload.mp_name).to eq(nil)
      end
    end
  end

  describe ".refresh" do
    context "when Parliament has dissolved" do
      let!(:constituency_1) do
        FactoryGirl.create(:constituency, :coventry_north_east)
      end

      let!(:constituency_2) do
        FactoryGirl.create(:constituency, :sheffield_brightside_and_hillsborough)
      end

      before do
        stub_api_request_for("CV21PH").to_return(api_response(:ok, "coventry_north_east"))
        stub_api_request_for("S61AR").to_return(api_response(:ok, "sheffield_brightside_and_hillsborough"))
      end

      it "updates the existing constituencies" do
        expect {
          Constituency.refresh
        }.to change {
          [
            constituency_1.reload.mp_name,
            constituency_2.reload.mp_name
          ]
        }.from(["Colleen Fletcher MP", "Gill Furniss"]).to([nil, nil])
      end
    end
  end

  describe "#sitting_mp?" do
    context "when the MP details are available" do
      let(:constituency) { FactoryGirl.build(:constituency, mp_id: "4477", mp_name: "Harry Harpham") }

      it "returns true" do
        expect(constituency.sitting_mp?).to be true
      end
    end

    context "when the MP details are not available" do
      let(:constituency) { FactoryGirl.build(:constituency, mp_id: nil, mp_name: nil) }

      it "returns false" do
        expect(constituency.sitting_mp?).to be false
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

  describe "#example_postcode" do
    context "when the example postcode is not cached" do
      let!(:constituency) { FactoryGirl.create(:constituency, :coventry_north_east, :no_example_postcode) }
      let!(:area_url) { "http://mapit/area/E14000649" }
      let!(:geometry_url) { "http://mapit/area/65636/geometry" }
      let!(:postcode_url) { "http://mapit/nearest/27700/436297.8961978419,281104.15840755054" }

      let!(:area_response) do
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{"id":65636}' }
      end

      let!(:geometry_response) do
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{"centre_e":436297.8961978419,"centre_n":281104.15840755054}' }
      end

      let!(:postcode_response) do
        { status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{"postcode":{"postcode":"CV2 1PH"}}' }
      end

      before do
        stub_request(:get, area_url).to_return(area_response)
        stub_request(:get, geometry_url).to_return(geometry_response)
        stub_request(:get, postcode_url).to_return(postcode_response)
      end

      context "and a postcode lookup mismatch doesn't occur" do
        before do
          stub_api_request_for("CV21PH").to_return(api_response(:ok, "coventry_north_east"))
        end

        it "fetches the example postcode from the Mapit API" do
          expect(constituency.example_postcode).to eq("CV21PH")
        end

        it "saves the example postcode in the constituency record" do
          expect {
            constituency.example_postcode
          }.to change {
            constituency.reload[:example_postcode]
          }.from(nil).to("CV21PH")
        end
      end

      context "and a postcode lookup mismatch occurs" do
        before do
          stub_api_request_for("CV21PH").to_return(api_response(:ok, "sheffield_brightside_and_hillsborough"))
        end

        it "raises a RuntimeError" do
          expect { constituency.example_postcode }.to raise_error(RuntimeError)
        end
      end
    end

    context "when the example postcode is cached" do
      let!(:constituency) { FactoryGirl.create(:constituency, :coventry_north_east) }

      it "doesn't make an API request" do
        expect(WebMock).not_to have_requested(:get, "mapit")
        expect(constituency.example_postcode).to eq("CV21PH")
      end
    end
  end

  describe "#refresh" do
    context "when Parliament has dissolved" do
      let!(:constituency) do
        FactoryGirl.create(:constituency, :coventry_north_east)
      end

      before do
        stub_api_request_for("CV21PH").to_return(api_response(:ok, "coventry_north_east"))
      end

      it "updates the existing constituency" do
        expect {
          constituency.refresh
        }.to change {
          constituency.reload.mp_name
        }.from("Colleen Fletcher MP").to(nil)
      end
    end

    context "when there is no example postcode" do
      let!(:constituency) do
        FactoryGirl.create(:constituency, :coventry_north_east)
      end

      before do
        expect(constituency).to receive(:example_postcode).and_return(nil)
      end

      it "doesn't update the constituency" do
        expect {
          constituency.refresh
        }.not_to change {
          constituency.reload.mp_name
        }
      end
    end

    context "when a postcode lookup mismatch occurs" do
      let!(:constituency) do
        FactoryGirl.create(:constituency, :coventry_north_east)
      end

      before do
        stub_api_request_for("CV21PH").to_return(api_response(:ok, "sheffield_brightside_and_hillsborough"))
      end

      it "raises a RuntimeError" do
        expect { constituency.refresh }.to raise_error(RuntimeError)
      end
    end
  end
end
