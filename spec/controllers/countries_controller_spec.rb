require 'rails_helper'

RSpec.describe CountriesController, type: :controller do
  shared_examples "a Country API controller" do
    it "responds with 200 OK" do
      expect(response.status).to eq(200)
    end

    it "assigns the @countries instance variable" do
      expect(assigns[:countries]).not_to be_nil
    end

    it "renders the countries/index template" do
      expect(response).to render_template("countries/index")
    end

    it "sets the Access-Control-Allow-Origin header to '*'" do
      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    end

    it "sets the Access-Control-Allow-Methods header to 'GET'" do
      expect(response.headers["Access-Control-Allow-Methods"]).to eq("GET")
    end

    it "sets the Access-Control-Allow-Headers header to 'Origin, X-Requested-With, Content-Type, Accept'" do
      expect(response.headers["Access-Control-Allow-Headers"]).to eq("Origin, X-Requested-With, Content-Type, Accept")
    end
  end

  describe "GET /countries.json" do
    before do
      get :index, format: "json"
    end

    it_behaves_like "a Country API controller"
  end

  describe "GET /countries.geojson" do
    before do
      get :index, format: "geojson"
    end

    it_behaves_like "a Country API controller"
  end

  describe "GET /countries.js" do
    before do
      get :index, format: "js"
    end

    it "responds with 200 OK" do
      expect(response.status).to eq(200)
    end

    it "assigns the @countries instance variable" do
      expect(assigns[:countries]).not_to be_nil
    end

    it "renders the countries/index template" do
      expect(response).to render_template("countries/index")
    end

    it "does not set the Access-Control-Allow-Origin header to '*'" do
      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
    end

    it "does not set the Access-Control-Allow-Methods header to 'GET'" do
      expect(response.headers["Access-Control-Allow-Methods"]).to be_nil
    end

    it "does not set the Access-Control-Allow-Headers header to 'Origin, X-Requested-With, Content-Type, Accept'" do
      expect(response.headers["Access-Control-Allow-Headers"]).to be_nil
    end
  end
end
