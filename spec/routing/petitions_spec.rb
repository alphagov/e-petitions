require 'rails_helper'

RSpec.describe "routes for petitions", type: :routes do
  describe "English", english: true do
    it "routes GET /petitions to petitions#index" do
      expect(get("/petitions")).to route_to(controller: "petitions", action: "index")
      expect(petitions_path).to eq("/petitions")
    end

    it "routes GET /petitions/new to petitions#new" do
      expect(get("/petitions/new")).to route_to(controller: "petitions", action: "new")
      expect(new_petition_path).to eq("/petitions/new")
    end

    it "routes POST /petitions/new to petitions#create" do
      expect(post("/petitions/new")).to route_to(controller: "petitions", action: "create")
      expect(new_petition_path).to eq("/petitions/new")
    end

    it "doesn't route POST /petitions" do
      expect(post("/petitions")).not_to be_routable
    end

    it "routes GET /petitions/:id to petitions#show" do
      expect(get("/petitions/1")).to route_to(controller: "petitions", action: "show", id: "1")
      expect(petition_path("1")).to eq("/petitions/1")
    end

    it "doesn't route GET /petitions/:id/edit" do
      expect(patch("/petitions/1/edit")).not_to be_routable
    end

    it "doesn't route PATCH /petitions/:id" do
      expect(patch("/petitions/1")).not_to be_routable
    end

    it "doesn't route PUT /petitions/:id" do
      expect(put("/petitions/1")).not_to be_routable
    end

    it "doesn't route DELETE /petitions/:id" do
      expect(delete("/petitions/1")).not_to be_routable
    end

    it "routes GET /petitions/check to petitions#check" do
      expect(get("/petitions/check")).to route_to(controller: "petitions", action: "check")
      expect(check_petitions_path).to eq("/petitions/check")
    end

    it "routes GET /petitions/check_results to petitions#check_results" do
      expect(get("/petitions/check_results")).to route_to(controller: "petitions", action: "check_results")
      expect(check_results_petitions_path).to eq("/petitions/check_results")
    end

    it "routes GET /petitions/:id/count to petitions#count" do
      expect(get("/petitions/1/count")).to route_to(controller: "petitions", action: "count", id: "1")
      expect(count_petition_path("1")).to eq("/petitions/1/count")
    end

    it "routes GET /petitions/:id/thank-you to petitions#thank_you" do
      expect(get("/petitions/1/thank-you")).to route_to(controller: "petitions", action: "thank_you", id: "1")
      expect(thank_you_petition_path("1")).to eq("/petitions/1/thank-you")
    end

    it "routes GET /petitions/:id/gathering-support to petitions#gathering_support" do
      expect(get("/petitions/1/gathering-support")).to route_to(controller: "petitions", action: "gathering_support", id: "1")
      expect(gathering_support_petition_path("1")).to eq("/petitions/1/gathering-support")
    end

    it "routes GET /petitions/:id/moderation-info to petitions#moderation_info" do
      expect(get("/petitions/1/moderation-info")).to route_to(controller: "petitions", action: "moderation_info", id: "1")
      expect(moderation_info_petition_path("1")).to eq("/petitions/1/moderation-info")
    end

    describe "redirects" do
      it "GET /deisebau" do
        expect(get("/deisebau")).to redirect_to("/petitions", 308)
      end

      it "GET /deisebau/newydd" do
        expect(get("/deisebau/newydd")).to redirect_to("/petitions/new", 308)
      end

      it "POST /deisebau/newydd" do
        expect(post("/deisebau/newydd")).to redirect_to("/petitions/new", 308)
      end

      it "GET /deisebau/:id" do
        expect(get("/deisebau/1")).to redirect_to("/petitions/1", 308)
      end

      it "GET /deisebau/gwirio" do
        expect(get("/deisebau/gwirio")).to redirect_to("/petitions/check", 308)
      end

      it "GET /deisebau/gwirio_canlyniadau" do
        expect(get("/deisebau/gwirio_canlyniadau")).to redirect_to("/petitions/check_results", 308)
      end

      it "GET /deisebau/:id/cyfrif" do
        expect(get("/deisebau/1/cyfrif")).to redirect_to("/petitions/1/count", 308)
      end

      it "GET /deisebau/:id/diolch" do
        expect(get("/deisebau/1/diolch")).to redirect_to("/petitions/1/thank-you", 308)
      end

      it "GET /deisebau/:id/casglu-cefnogaeth" do
        expect(get("/deisebau/1/casglu-cefnogaeth")).to redirect_to("/petitions/1/gathering-support", 308)
      end

      it "GET /deisebau/:id/cymedroli-gwybodaeth" do
        expect(get("/deisebau/1/cymedroli-gwybodaeth")).to redirect_to("/petitions/1/moderation-info", 308)
      end
    end
  end

  describe "Welsh", welsh: true do
    it "routes GET /deisebau to petitions#index" do
      expect(get("/deisebau")).to route_to(controller: "petitions", action: "index")
      expect(petitions_path).to eq("/deisebau")
    end

    it "routes GET /deisebau/newydd to petitions#new" do
      expect(get("/deisebau/newydd")).to route_to(controller: "petitions", action: "new")
      expect(new_petition_path).to eq("/deisebau/newydd")
    end

    it "routes POST /deisebau/newydd to petitions#create" do
      expect(post("/deisebau/newydd")).to route_to(controller: "petitions", action: "create")
      expect(new_petition_path).to eq("/deisebau/newydd")
    end

    it "doesn't route POST /petitions" do
      expect(post("/deisebau")).not_to be_routable
    end

    it "routes GET /deisebau/:id to petitions#show" do
      expect(get("/deisebau/1")).to route_to(controller: "petitions", action: "show", id: "1")
      expect(petition_path("1")).to eq("/deisebau/1")
    end

    it "doesn't route GET /deisebau/:id/golygu" do
      expect(patch("/deisebau/1/golygu")).not_to be_routable
    end

    it "doesn't route PATCH /deisebau/:id" do
      expect(patch("/deisebau/1")).not_to be_routable
    end

    it "doesn't route PUT /deisebau/:id" do
      expect(put("/deisebau/1")).not_to be_routable
    end

    it "doesn't route DELETE /deisebau/:id" do
      expect(delete("/deisebau/1")).not_to be_routable
    end

    it "routes GET /deisebau/gwirio to petitions#check" do
      expect(get("/deisebau/gwirio")).to route_to(controller: "petitions", action: "check")
      expect(check_petitions_path).to eq("/deisebau/gwirio")
    end

    it "routes GET /deisebau/gwirio_canlyniadau to petitions#check_results" do
      expect(get("/deisebau/gwirio_canlyniadau")).to route_to(controller: "petitions", action: "check_results")
      expect(check_results_petitions_path).to eq("/deisebau/gwirio_canlyniadau")
    end

    it "routes GET /deisebau/:id/cyfrif to petitions#count" do
      expect(get("/deisebau/1/cyfrif")).to route_to(controller: "petitions", action: "count", id: "1")
      expect(count_petition_path("1")).to eq("/deisebau/1/cyfrif")
    end

    it "routes GET /deisebau/:id/diolch to petitions#thank_you" do
      expect(get("/deisebau/1/diolch")).to route_to(controller: "petitions", action: "thank_you", id: "1")
      expect(thank_you_petition_path("1")).to eq("/deisebau/1/diolch")
    end

    it "routes GET /deisebau/:id/casglu-cefnogaeth to petitions#gathering_support" do
      expect(get("/deisebau/1/casglu-cefnogaeth")).to route_to(controller: "petitions", action: "gathering_support", id: "1")
      expect(gathering_support_petition_path("1")).to eq("/deisebau/1/casglu-cefnogaeth")
    end

    it "routes GET /deisebau/:id/cymedroli-gwybodaeth to petitions#moderation_info" do
      expect(get("/deisebau/1/cymedroli-gwybodaeth")).to route_to(controller: "petitions", action: "moderation_info", id: "1")
      expect(moderation_info_petition_path("1")).to eq("/deisebau/1/cymedroli-gwybodaeth")
    end

    describe "redirects" do
      it "GET /petitions" do
        expect(get("/petitions")).to redirect_to("/deisebau", 308)
      end

      it "GET /petitions/new" do
        expect(get("/petitions/new")).to redirect_to("/deisebau/newydd", 308)
      end

      it "POST /petitions/new" do
        expect(post("/petitions/new")).to redirect_to("/deisebau/newydd", 308)
      end

      it "GET /petitions/:id" do
        expect(get("/petitions/1")).to redirect_to("/deisebau/1", 308)
      end

      it "GET /petitions/check" do
        expect(get("/petitions/check")).to redirect_to("/deisebau/gwirio", 308)
      end

      it "GET /petitions/check_results" do
        expect(get("/petitions/check_results")).to redirect_to("/deisebau/gwirio_canlyniadau", 308)
      end

      it "GET /petitions/:id/count" do
        expect(get("/petitions/1/count")).to redirect_to("/deisebau/1/cyfrif", 308)
      end

      it "GET /petitions/:id/thank-you" do
        expect(get("/petitions/1/thank-you")).to redirect_to("/deisebau/1/diolch", 308)
      end

      it "GET /petitions/:id/gathering-support" do
        expect(get("/petitions/1/gathering-support")).to redirect_to("/deisebau/1/casglu-cefnogaeth", 308)
      end

      it "GET /petitions/:id/moderation-info" do
        expect(get("/petitions/1/moderation-info")).to redirect_to("/deisebau/1/cymedroli-gwybodaeth", 308)
      end
    end
  end
end
