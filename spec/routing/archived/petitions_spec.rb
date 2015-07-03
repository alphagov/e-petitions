require 'rails_helper'

RSpec.describe "routes for Archived Petitions", type: :routes do
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
