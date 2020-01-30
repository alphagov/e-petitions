require 'rails_helper'

RSpec.describe "routes for Archived Petitions", type: :routes do
  describe "English", english: true do
    it "routes GET /archived/petitions to archived/petitions#index" do
      expect(get("/archived/petitions")).to route_to("archived/petitions#index")
    end

    it "routes GET /archived/petitions/new to archived/petitions#show" do
      expect(get("/archived/petitions/new")).to route_to("archived/petitions#show", id: "new")
    end

    it "doesn't route POST /archived/petitions" do
      expect(post("/archived/petitions")).not_to be_routable
    end

    it "routes GET /archived/petitions/1 to archived/petitions#show" do
      expect(get("/archived/petitions/1")).to route_to("archived/petitions#show", id: "1")
    end

    it "doesn't route GET /archived/petitions/1/edit" do
      expect(get("/archived/petitions/1/edit")).not_to be_routable
    end

    it "doesn't route PUT /archived/petitions/1" do
      expect(put("/archived/petitions/1")).not_to be_routable
    end

    it "doesn't route PATCH /archived/petitions/1" do
      expect(patch("/archived/petitions/1")).not_to be_routable
    end

    it "doesn't route DELETE /archived/petitions/1" do
      expect(delete("/archived/petitions/1")).not_to be_routable
    end

    describe "redirects" do
      it "GET /archifwyd/deisebau" do
        expect(get("/archifwyd/deisebau")).to redirect_to("/archived/petitions", 308)
      end

      it "GET /archifwyd/deisebau/newydd" do
        expect(get("/archifwyd/deisebau/newydd")).to redirect_to("/archived/petitions/newydd", 308)
      end

      it "GET /archifwyd/deisebau/1" do
        expect(get("/archifwyd/deisebau/1")).to redirect_to("/archived/petitions/1", 308)
      end
    end

    describe "url helpers" do
      describe "#archived_petitions" do
        it "generates /archived/petitions" do
          expect(archived_petitions_path).to eq("/archived/petitions")
        end
      end

      describe "#new_archived_petition" do
        it "raises a NameError" do
          expect{ new_archived_petition_path }.to raise_error(NameError)
        end
      end

      describe "#archived_petition" do
        it "generates /archived/petitions/1" do
          expect(archived_petition_path("1")).to eq("/archived/petitions/1")
        end
      end

      describe "#edit_archived_petition" do
        it "raises a NameError" do
          expect{ edit_archived_petition_path }.to raise_error(NameError)
        end
      end
    end
  end

  describe "Welsh", welsh: true do
    it "routes GET /archifwyd/deisebau to archived/petitions#index" do
      expect(get("/archifwyd/deisebau")).to route_to("archived/petitions#index")
    end

    it "routes GET /archifwyd/deisebau/newydd to archived/petitions#show" do
      expect(get("/archifwyd/deisebau/newydd")).to route_to("archived/petitions#show", id: "newydd")
    end

    it "doesn't route POST /archifwyd/deisebau" do
      expect(post("/archifwyd/deisebau")).not_to be_routable
    end

    it "routes GET /archifwyd/deisebau/1 to archived/petitions#show" do
      expect(get("/archifwyd/deisebau/1")).to route_to("archived/petitions#show", id: "1")
    end

    it "doesn't route GET /archifwyd/deisebau/1/golygu" do
      expect(get("/archifwyd/deisebau/1/golygu")).not_to be_routable
    end

    it "doesn't route PUT /archifwyd/deisebau/1" do
      expect(put("/archifwyd/deisebau/1")).not_to be_routable
    end

    it "doesn't route PATCH /archifwyd/deisebau/1" do
      expect(patch("/archifwyd/deisebau/1")).not_to be_routable
    end

    it "doesn't route DELETE /archifwyd/deisebau/1" do
      expect(delete("/archifwyd/deisebau/1")).not_to be_routable
    end

    describe "redirects" do
      it "GET /archived/petitions" do
        expect(get("/archived/petitions")).to redirect_to("/archifwyd/deisebau", 308)
      end

      it "GET /archived/petitions/new" do
        expect(get("/archived/petitions/new")).to redirect_to("/archifwyd/deisebau/new", 308)
      end

      it "GET /archived/petitions/1" do
        expect(get("/archived/petitions/1")).to redirect_to("/archifwyd/deisebau/1", 308)
      end
    end

    describe "url helpers" do
      describe "#archived_petitions" do
        it "generates /archifwyd/deisebau" do
          expect(archived_petitions_path).to eq("/archifwyd/deisebau")
        end
      end

      describe "#new_archived_petition" do
        it "raises a NameError" do
          expect{ new_archived_petition_path }.to raise_error(NameError)
        end
      end

      describe "#archived_petition" do
        it "generates /archifwyd/deisebau/1" do
          expect(archived_petition_path("1")).to eq("/archifwyd/deisebau/1")
        end
      end

      describe "#edit_archived_petition" do
        it "raises a NameError" do
          expect{ edit_archived_petition_path }.to raise_error(NameError)
        end
      end
    end
  end
end
