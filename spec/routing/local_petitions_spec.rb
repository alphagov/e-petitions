require 'rails_helper'

RSpec.describe "routes for local petitions", type: :routes do
  describe "English", english: true do
    it "routes GET /petitions/local to local_petitions#index" do
      expect(get("/petitions/local")).to route_to("local_petitions#index")
    end

    it "routes GET /petitions/local/cardiff to local_petitions#show" do
      expect(get("/petitions/local/cardiff")).to route_to("local_petitions#show", id: "cardiff")
    end

    it "routes GET /petitions/local/cardiff/all to local_petitions#show" do
      expect(get("/petitions/local/cardiff/all")).to route_to("local_petitions#all", id: "cardiff")
    end

    describe "redirects" do
      it "GET /deisebau/lleol" do
        expect(get("/deisebau/lleol")).to redirect_to("/petitions/local", 308)
      end

      it "GET /deisebau/lleol/caerdydd" do
        expect(get("/deisebau/lleol/caerdydd")).to redirect_to("/petitions/local/caerdydd", 308)
      end

      it "GET /deisebau/lleol/caerdydd/bob" do
        expect(get("/deisebau/lleol/caerdydd/bob")).to redirect_to("/petitions/local/caerdydd/all", 308)
      end
    end
  end

  describe "Welsh", welsh: true do
    it "routes GET /deisebau/lleol to local_petitions#index" do
      expect(get("/deisebau/lleol")).to route_to("local_petitions#index")
    end

    it "routes GET /deisebau/lleol/caerdydd to local_petitions#show" do
      expect(get("/deisebau/lleol/caerdydd")).to route_to("local_petitions#show", id: "caerdydd")
    end

    it "routes GET /deisebau/lleol/caerdydd/bob to local_petitions#all" do
      expect(get("/deisebau/lleol/caerdydd/bob")).to route_to("local_petitions#all", id: "caerdydd")
    end

    describe "redirects" do
      it "GET /petitions/local" do
        expect(get("/petitions/local")).to redirect_to("/deisebau/lleol", 308)
      end

      it "GET /petitions/local/cardiff" do
        expect(get("/petitions/local/cardiff")).to redirect_to("/deisebau/lleol/cardiff", 308)
      end

      it "GET /petitions/local/cardiff/all" do
        expect(get("/petitions/local/cardiff/all")).to redirect_to("/deisebau/lleol/cardiff/bob", 308)
      end
    end
  end
end
