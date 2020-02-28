require 'rails_helper'

RSpec.describe LocalPetitionsController, type: :controller do
  let(:constituency) { FactoryBot.create(:constituency, :cardiff_south_and_penarth) }

  describe "GET /petitions/local" do
    context "when the postcode is valid" do
      before do
        expect(Constituency).to receive(:find_by_postcode).with("CF991NA").and_return(constituency)

        get :index, params: { postcode: "cf99 1na" }
      end

      it "assigns the sanitized postcode" do
        expect(assigns(:postcode)).to eq("CF991NA")
      end

      it "redirects to the constituency page for current popular petitions" do
        expect(response).to redirect_to("/petitions/local/W09000043")
      end
    end

    context "when the postcode is invalid" do
      before do
        expect(Constituency).to receive(:find_by_postcode).with("SW1A1AA").and_return(nil)
        get :index, params: { postcode: "sw1a 1aa" }
      end

      it "assigns the sanitized postcode" do
        expect(assigns(:postcode)).to eq("SW1A1AA")
      end

      it "responds successfully" do
        expect(response).to be_successful
      end

      it "renders the index template" do
        expect(response).to render_template("local_petitions/index")
      end

      it "doesn't assign the instance variables" do
        expect(assigns(:constituency)).to be_nil
        expect(assigns(:member)).to be_nil
        expect(assigns(:region)).to be_nil
        expect(assigns(:members)).to be_nil
        expect(assigns(:petitions)).to be_nil
      end
    end

    context "when the postcode is blank" do
      before do
        expect(Constituency).not_to receive(:find_by_postcode)
        get :index, params: { postcode: "" }
      end

      it "responds successfully" do
        expect(response).to be_successful
      end

      it "renders the index template" do
        expect(response).to render_template("local_petitions/index")
      end
    end

    context "when the postcode is not set" do
      before do
        expect(Constituency).not_to receive(:find_by_postcode)
        get :index
      end

      it "responds successfully" do
        expect(response).to be_successful
      end

      it "renders the index template" do
        expect(response).to render_template("local_petitions/index")
      end
    end
  end

  describe "GET /petitions/local/:id" do
    let(:petitions) { double(:petitions) }
    let(:member) { double(:member) }
    let(:region) { double(:region) }
    let(:members) { double(:members) }

    before do
      expect(Constituency).to receive(:find).with("W09000043").and_return(constituency)
      expect(constituency).to receive(:member).and_return(member)
      expect(constituency).to receive(:region).and_return(region)
      expect(region).to receive(:members).and_return(members)
      expect(Petition).to receive(:popular_in_constituency).with("W09000043", 50).and_return(petitions)

      get :show, params: { id: "W09000043" }
    end

    it "renders the all template" do
      expect(response).to render_template("local_petitions/show")
    end

    it "assigns the instance variables" do
      expect(assigns(:constituency)).to eq(constituency)
      expect(assigns(:member)).to eq(member)
      expect(assigns(:region)).to eq(region)
      expect(assigns(:members)).to eq(members)
      expect(assigns(:petitions)).to eq(petitions)
    end
  end

  describe "GET /petitions/local/:id/all" do
    let(:petitions) { double(:petitions) }
    let(:member) { double(:member) }
    let(:region) { double(:region) }
    let(:members) { double(:members) }

    before do
      expect(Constituency).to receive(:find).with("W09000043").and_return(constituency)
      expect(constituency).to receive(:member).and_return(member)
      expect(constituency).to receive(:region).and_return(region)
      expect(region).to receive(:members).and_return(members)
      expect(Petition).to receive(:all_popular_in_constituency).with("W09000043", 50).and_return(petitions)

      get :all, params: { id: "W09000043" }
    end

    it "renders the all template" do
      expect(response).to render_template("local_petitions/all")
    end

    it "assigns the instance variables" do
      expect(assigns(:constituency)).to eq(constituency)
      expect(assigns(:member)).to eq(member)
      expect(assigns(:region)).to eq(region)
      expect(assigns(:members)).to eq(members)
      expect(assigns(:petitions)).to eq(petitions)
    end
  end
end
