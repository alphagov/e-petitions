require 'rails_helper'

RSpec.describe "routes for sponsor", type: :routes do
  describe "English", english: true do
    # Routes nested to /petition/:petition_id
    it "doesn't route GET /petitions/1/sponsors" do
      expect(get("/petitions/1/sponsors")).not_to be_routable
    end

    it "routes GET /petitions/1/sponsors/new to sponsors#new" do
      expect(get("/petitions/1/sponsors/new")).to route_to("sponsors#new", petition_id: "1")
    end

    it "routes POST /petitions/1/sponsors/new to sponsors#confirm" do
      expect(post("/petitions/1/sponsors/new")).to route_to("sponsors#confirm", petition_id: "1")
    end

    it "routes POST /petitions/1/sponsors to sponsors#create" do
      expect(post("/petitions/1/sponsors")).to route_to("sponsors#create", petition_id: "1")
    end

    it "routes GET /petitions/1/sponsors/thank-you to sponsors#thank_you" do
      expect(get("/petitions/1/sponsors/thank-you")).to route_to("sponsors#thank_you", petition_id: "1")
    end

    it "doesn't route GET /petitions/1/sponsors/2" do
      expect(get("/petitions/1/sponsors/2")).not_to be_routable
    end

    it "doesn't route GET /petitions/1/sponsors/2/edit" do
      expect(get("/petitions/1/sponsors/2/edit")).not_to be_routable
    end

    it "doesn't route PATCH /petitions/1/sponsors/2" do
      expect(patch("/petitions/1/sponsors/2")).not_to be_routable
    end

    it "doesn't route PUT /petitions/1/sponsors/2" do
      expect(put("/petitions/1/sponsors/2")).not_to be_routable
    end

    it "doesn't route DELETE /petitions/1/sponsors/2" do
      expect(delete("/petitions/1/sponsors/2")).not_to be_routable
    end

    # un-nested routes
    it "routes GET /sponsors/1/verify to sponsors#verify" do
      expect(get("/sponsors/1/verify?token=abcdef1234567890")).
        to route_to("sponsors#verify", id: "1", token: "abcdef1234567890")

      expect(verify_sponsor_path("1", token: "abcdef1234567890")).to eq("/sponsors/1/verify?token=abcdef1234567890")
    end

    it "doesn't route GET /sponsors/1/unsubscribe" do
      expect(delete("/sponsors/1/unsubscribe")).not_to be_routable
    end

    it "routes GET /sponsors/1/sponsored to sponsors#signed" do
      expect(get("/sponsors/1/sponsored?token=abcdef1234567890")).
        to route_to("sponsors#signed", id: "1", token: "abcdef1234567890")

      expect(signed_sponsor_path("1", token: "abcdef1234567890")).to eq("/sponsors/1/sponsored?token=abcdef1234567890")
    end

    it "doesn't route GET /sponsors" do
      expect(get("/sponsors")).not_to be_routable
    end

    it "doesn't route GET /sponsors/new" do
      expect(get("/sponsors/new")).not_to be_routable
    end

    it "doesn't route POST /sponsors" do
      expect(post("/sponsors")).not_to be_routable
    end

    it "doesn't route GET /sponsors/1" do
      expect(get("/sponsors/2")).not_to be_routable
    end

    it "doesn't route GET /sponsors/1/edit" do
      expect(get("/sponsors/2/edit")).not_to be_routable
    end

    it "doesn't route PATCH /sponsors/1" do
      expect(patch("/sponsors/2")).not_to be_routable
    end

    it "doesn't route DELETE /sponsors/1" do
      expect(delete("/sponsors/2")).not_to be_routable
    end

    describe "redirects" do
      it "GET /deisebau/1/noddwyr/newydd" do
        expect(get("/deisebau/1/noddwyr/newydd")).to redirect_to("/petitions/1/sponsors/new", 308)
      end

      it "POST /deisebau/1/noddwyr/newydd" do
        expect(post("/deisebau/1/noddwyr/newydd")).to redirect_to("/petitions/1/sponsors/new", 308)
      end

      it "POST /deisebau/1/noddwyr" do
        expect(post("/deisebau/1/noddwyr")).to redirect_to("/petitions/1/sponsors", 308)
      end

      it "GET /deisebau/1/noddwyr/diolch" do
        expect(get("/deisebau/1/noddwyr/diolch")).to redirect_to("/petitions/1/sponsors/thank-you", 308)
      end

      it "GET /noddwyr/1/gwirio" do
        expect(get("/noddwyr/1/gwirio?token=abcdef1234567890")).to redirect_to("/sponsors/1/verify?token=abcdef1234567890", 308)
      end

      it "GET /noddwyr/1/noddedig" do
        expect(get("/noddwyr/1/noddedig?token=abcdef1234567890")).to redirect_to("/sponsors/1/sponsored?token=abcdef1234567890", 308)
      end
    end
  end

  describe "Welsh", welsh: true do
    # Routes nested to /deisebau/:petition_id
    it "doesn't route GET /deisebau/1/noddwyr" do
      expect(get("/deisebau/1/noddwyr")).not_to be_routable
    end

    it "routes GET /deisebau/1/noddwyr/newydd to sponsors#new" do
      expect(get("/deisebau/1/noddwyr/newydd")).to route_to("sponsors#new", petition_id: "1")
    end

    it "routes POST /deisebau/1/noddwyr/newydd to sponsors#confirm" do
      expect(post("/deisebau/1/noddwyr/newydd")).to route_to("sponsors#confirm", petition_id: "1")
    end

    it "routes POST /deisebau/1/noddwyr to sponsors#create" do
      expect(post("/deisebau/1/noddwyr")).to route_to("sponsors#create", petition_id: "1")
    end

    it "routes GET /deisebau/1/noddwyr/diolch to sponsors#thank_you" do
      expect(get("/deisebau/1/noddwyr/diolch")).to route_to("sponsors#thank_you", petition_id: "1")
    end

    it "doesn't route GET /deisebau/1/noddwyr/2" do
      expect(get("/deisebau/1/noddwyr/2")).not_to be_routable
    end

    it "doesn't route GET /deisebau/1/noddwyr/2/golygu" do
      expect(get("/deisebau/1/noddwyr/2/golygu")).not_to be_routable
    end

    it "doesn't route PATCH /deisebau/1/noddwyr/2" do
      expect(patch("/deisebau/1/noddwyr/2")).not_to be_routable
    end

    it "doesn't route PUT /deisebau/1/noddwyr/2" do
      expect(put("/deisebau/1/noddwyr/2")).not_to be_routable
    end

    it "doesn't route DELETE /deisebau/1/noddwyr/2" do
      expect(delete("/deisebau/1/noddwyr/2")).not_to be_routable
    end

    # un-nested routes
    it "routes GET /noddwyr/1/gwirio to sponsors#verify" do
      expect(get("/noddwyr/1/gwirio?token=abcdef1234567890")).
        to route_to("sponsors#verify", id: "1", token: "abcdef1234567890")

      expect(verify_sponsor_path("1", token: "abcdef1234567890")).to eq("/noddwyr/1/gwirio?token=abcdef1234567890")
    end

    it "doesn't route GET /noddwyr/1/dad-danysgrifio" do
      expect(delete("/noddwyr/1/dad-danysgrifio")).not_to be_routable
    end

    it "routes GET /noddwyr/1/noddedig to sponsors#signed" do
      expect(get("/noddwyr/1/noddedig?token=abcdef1234567890")).
        to route_to("sponsors#signed", id: "1", token: "abcdef1234567890")

      expect(signed_sponsor_path("1", token: "abcdef1234567890")).to eq("/noddwyr/1/noddedig?token=abcdef1234567890")
    end

    it "doesn't route GET /noddwyr" do
      expect(get("/noddwyr")).not_to be_routable
    end

    it "doesn't route GET /noddwyr/newydd" do
      expect(get("/noddwyr/newydd")).not_to be_routable
    end

    it "doesn't route POST /noddwyr" do
      expect(post("/noddwyr")).not_to be_routable
    end

    it "doesn't route GET /noddwyr/1" do
      expect(get("/noddwyr/2")).not_to be_routable
    end

    it "doesn't route GET /noddwyr/1/golygu" do
      expect(get("/noddwyr/2/golygu")).not_to be_routable
    end

    it "doesn't route PATCH /noddwyr/1" do
      expect(patch("/noddwyr/2")).not_to be_routable
    end

    it "doesn't route DELETE /noddwyr/1" do
      expect(delete("/noddwyr/2")).not_to be_routable
    end

    describe "redirects" do
      it "GET /petitions/1/sponsors/new" do
        expect(get("/petitions/1/sponsors/new")).to redirect_to("/deisebau/1/noddwyr/newydd", 308)
      end

      it "POST /petitions/1/sponsors/new" do
        expect(post("/petitions/1/sponsors/new")).to redirect_to("/deisebau/1/noddwyr/newydd", 308)
      end

      it "POST /petitions/1/sponsors" do
        expect(post("/petitions/1/sponsors")).to redirect_to("/deisebau/1/noddwyr", 308)
      end

      it "GET /petitions/1/sponsors/thank-you" do
        expect(get("/petitions/1/sponsors/thank-you")).to redirect_to("/deisebau/1/noddwyr/diolch", 308)
      end

      it "GET /sponsors/1/verify" do
        expect(get("/sponsors/1/verify?token=abcdef1234567890")).to redirect_to("/noddwyr/1/gwirio?token=abcdef1234567890", 308)
      end

      it "GET /sponsors/1/sponsored" do
        expect(get("/sponsors/1/sponsored?token=abcdef1234567890")).to redirect_to("/noddwyr/1/noddedig?token=abcdef1234567890", 308)
      end
    end
  end
end
