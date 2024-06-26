require 'rails_helper'

RSpec.describe ParliamentsController, type: :controller do
  describe "GET /parliaments.json" do
    before do
      get :index, format: "json"
    end

    it "responds with 200 OK" do
      expect(response.status).to eq(200)
    end

    it "assigns the @parliaments instance variable" do
      expect(assigns[:parliaments]).not_to be_nil
    end

    it "renders the constituencies/index template" do
      expect(response).to render_template("parliaments/index")
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
end
