require 'rails_helper'

RSpec.describe "routes for signatures", type: :routes do
  describe "English", english: true do
    # Routes nested to /petition/:petition_id
    it "doesn't route GET /petitions/1/signatures" do
      expect(get("/petitions/1/signatures")).not_to be_routable
    end

    it "routes GET /petitions/1/signatures/new to signatures#new" do
      expect(get("/petitions/1/signatures/new")).to route_to("signatures#new", petition_id: "1")
    end

    it "routes POST /petitions/1/signatures/new to signatures#confirm" do
      expect(post("/petitions/1/signatures/new")).to route_to("signatures#confirm", petition_id: "1")
    end

    it "routes POST /petitions/1/signatures to signatures#create" do
      expect(post("/petitions/1/signatures")).to route_to("signatures#create", petition_id: "1")
    end

    it "routes GET /petitions/1/signatures/thank-you to signatures#thank_you" do
      expect(get("/petitions/1/signatures/thank-you")).to route_to("signatures#thank_you", petition_id: "1")
    end

    it "doesn't route GET /petitions/1/signatures/2" do
      expect(get("/petitions/1/signatures/2")).not_to be_routable
    end

    it "doesn't route GET /petitions/1/signatures/2/edit" do
      expect(get("/petitions/1/signatures/2/edit")).not_to be_routable
    end

    it "doesn't route PATCH /petitions/1/signatures/2" do
      expect(patch("/petitions/1/signatures/2")).not_to be_routable
    end

    it "doesn't route PUT /petitions/1/signatures/2" do
      expect(put("/petitions/1/signatures/2")).not_to be_routable
    end

    it "doesn't route DELETE /petitions/1/signatures/2" do
      expect(delete("/petitions/1/signatures/2")).not_to be_routable
    end

    # un-nested routes
    it "routes GET /signatures/1/verify to signatures#verify" do
      expect(get("/signatures/1/verify?token=abcdef1234567890")).
        to route_to("signatures#verify", id: "1", token: "abcdef1234567890")

      expect(verify_signature_path("1", token: "abcdef1234567890")).to eq("/signatures/1/verify?token=abcdef1234567890")
    end

    it "routes GET /signatures/1/unsubscribe to signatures#unsubscribe" do
      expect(get("/signatures/1/unsubscribe?token=abcdef1234567890")).
        to route_to("signatures#unsubscribe", id: "1", token: "abcdef1234567890")

      expect(unsubscribe_signature_path("1", token: "abcdef1234567890")).to eq("/signatures/1/unsubscribe?token=abcdef1234567890")
    end

    it "routes GET /signatures/1/signed to signatures#signed" do
      expect(get("/signatures/1/signed?token=abcdef1234567890")).
        to route_to("signatures#signed", id: "1", token: "abcdef1234567890")

      expect(signed_signature_path("1", token: "abcdef1234567890")).to eq("/signatures/1/signed?token=abcdef1234567890")
    end

    it "doesn't route GET /signatures" do
      expect(get("/signatures")).not_to be_routable
    end

    it "doesn't route GET /signatures/new" do
      expect(get("/signatures/new")).not_to be_routable
    end

    it "doesn't route POST /signatures" do
      expect(post("/signatures")).not_to be_routable
    end

    it "doesn't route GET /signatures/1" do
      expect(get("/signatures/2")).not_to be_routable
    end

    it "doesn't route GET /signatures/1/edit" do
      expect(get("/signatures/2/edit")).not_to be_routable
    end

    it "doesn't route PATCH /signatures/1" do
      expect(patch("/signatures/2")).not_to be_routable
    end

    it "doesn't route DELETE /signatures/1" do
      expect(delete("/signatures/2")).not_to be_routable
    end

    describe "redirects" do
      it "GET /deisebau/1/llofnodion/newydd" do
        expect(get("/deisebau/1/llofnodion/newydd")).to redirect_to("/petitions/1/signatures/new", 308)
      end

      it "POST /deisebau/1/noddwyr/newydd" do
        expect(post("/deisebau/1/llofnodion/newydd")).to redirect_to("/petitions/1/signatures/new", 308)
      end

      it "POST /deisebau/1/llofnodion" do
        expect(post("/deisebau/1/llofnodion")).to redirect_to("/petitions/1/signatures", 308)
      end

      it "GET /deisebau/1/llofnodion/diolch" do
        expect(get("/deisebau/1/llofnodion/diolch")).to redirect_to("/petitions/1/signatures/thank-you", 308)
      end

      it "GET /llofnodion/1/gwirio" do
        expect(get("/llofnodion/1/gwirio?token=abcdef1234567890")).to redirect_to("/signatures/1/verify?token=abcdef1234567890", 308)
      end

      it "GET /llofnodion/1/dad-danysgrifio" do
        expect(get("/llofnodion/1/dad-danysgrifio?token=abcdef1234567890")).to redirect_to("/signatures/1/unsubscribe?token=abcdef1234567890", 308)
      end

      it "GET /llofnodion/1/llofnodwyd" do
        expect(get("/llofnodion/1/llofnodwyd?token=abcdef1234567890")).to redirect_to("/signatures/1/signed?token=abcdef1234567890", 308)
      end
    end
  end

  describe "Welsh", welsh: true do
    # Routes nested to /petition/:petition_id
    it "doesn't route GET /deisebau/1/llofnodion" do
      expect(get("/deisebau/1/llofnodion")).not_to be_routable
    end

    it "routes GET /deisebau/1/llofnodion/newydd to signatures#new" do
      expect(get("/deisebau/1/llofnodion/newydd")).to route_to("signatures#new", petition_id: "1")
    end

    it "routes POST /deisebau/1/llofnodion/newydd to signatures#confirm" do
      expect(post("/deisebau/1/llofnodion/newydd")).to route_to("signatures#confirm", petition_id: "1")
    end

    it "routes POST /deisebau/1/llofnodion to signatures#create" do
      expect(post("/deisebau/1/llofnodion")).to route_to("signatures#create", petition_id: "1")
    end

    it "routes GET /deisebau/1/llofnodion/diolch to signatures#thank_you" do
      expect(get("/deisebau/1/llofnodion/diolch")).to route_to("signatures#thank_you", petition_id: "1")
    end

    it "doesn't route GET /deisebau/1/llofnodion/2" do
      expect(get("/deisebau/1/llofnodion/2")).not_to be_routable
    end

    it "doesn't route GET /deisebau/1/llofnodion/2/golygu" do
      expect(get("/deisebau/1/llofnodion/2/golygu")).not_to be_routable
    end

    it "doesn't route PATCH /deisebau/1/llofnodion/2" do
      expect(patch("/deisebau/1/llofnodion/2")).not_to be_routable
    end

    it "doesn't route PUT /deisebau/1/llofnodion/2" do
      expect(put("/deisebau/1/llofnodion/2")).not_to be_routable
    end

    it "doesn't route DELETE /deisebau/1/llofnodion/2" do
      expect(delete("/deisebau/1/llofnodion/2")).not_to be_routable
    end

    # un-nested routes
    it "routes GET /llofnodion/1/gwirio to signatures#verify" do
      expect(get("/llofnodion/1/gwirio?token=abcdef1234567890")).
        to route_to("signatures#verify", id: "1", token: "abcdef1234567890")

      expect(verify_signature_path("1", token: "abcdef1234567890")).to eq("/llofnodion/1/gwirio?token=abcdef1234567890")
    end

    it "routes GET /llofnodion/1/dad-danysgrifio to signatures#unsubscribe" do
      expect(get("/llofnodion/1/dad-danysgrifio?token=abcdef1234567890")).
        to route_to("signatures#unsubscribe", id: "1", token: "abcdef1234567890")

      expect(unsubscribe_signature_path("1", token: "abcdef1234567890")).to eq("/llofnodion/1/dad-danysgrifio?token=abcdef1234567890")
    end

    it "routes GET /llofnodion/1/llofnodwyd to signatures#signed" do
      expect(get("/llofnodion/1/llofnodwyd?token=abcdef1234567890")).
        to route_to("signatures#signed", id: "1", token: "abcdef1234567890")

      expect(signed_signature_path("1", token: "abcdef1234567890")).to eq("/llofnodion/1/llofnodwyd?token=abcdef1234567890")
    end

    it "doesn't route GET /llofnodion" do
      expect(get("/llofnodion")).not_to be_routable
    end

    it "doesn't route GET /llofnodion/newydd" do
      expect(get("/llofnodion/newydd")).not_to be_routable
    end

    it "doesn't route POST /llofnodion" do
      expect(post("/llofnodion")).not_to be_routable
    end

    it "doesn't route GET /llofnodion/1" do
      expect(post("/llofnodion/2")).not_to be_routable
    end

    it "doesn't route GET /llofnodion/1/golygu" do
      expect(post("/llofnodion/2/golygu")).not_to be_routable
    end

    it "doesn't route PATCH /llofnodion/1" do
      expect(patch("/llofnodion/2")).not_to be_routable
    end

    it "doesn't route DELETE /llofnodion/1" do
      expect(delete("/llofnodion/2")).not_to be_routable
    end

    describe "redirects" do
      it "GET /petitions/1/signatures/new" do
        expect(get("/petitions/1/signatures/new")).to redirect_to("/deisebau/1/llofnodion/newydd", 308)
      end

      it "POST /petitions/1/signatures/new" do
        expect(post("/petitions/1/signatures/new")).to redirect_to("/deisebau/1/llofnodion/newydd", 308)
      end

      it "POST /petitions/1/signatures" do
        expect(post("/petitions/1/signatures")).to redirect_to("/deisebau/1/llofnodion", 308)
      end

      it "GET /petitions/1/signatures/thank-you" do
        expect(get("/petitions/1/signatures/thank-you")).to redirect_to("/deisebau/1/llofnodion/diolch", 308)
      end

      it "GET /signatures/1/verify" do
        expect(get("/signatures/1/verify?token=abcdef1234567890")).to redirect_to("/llofnodion/1/gwirio?token=abcdef1234567890", 308)
      end

      it "GET /signatures/1/unsubscribe" do
        expect(get("/signatures/1/unsubscribe?token=abcdef1234567890")).to redirect_to("/llofnodion/1/dad-danysgrifio?token=abcdef1234567890", 308)
      end

      it "GET /signatures/1/signed" do
        expect(get("/signatures/1/signed?token=abcdef1234567890")).to redirect_to("/llofnodion/1/llofnodwyd?token=abcdef1234567890", 308)
      end
    end
  end
end
