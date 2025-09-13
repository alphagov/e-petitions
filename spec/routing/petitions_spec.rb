require 'rails_helper'

RSpec.describe "routes for petitions", type: :routes do
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

  it "routes GET /petitions/thank-you to petitions#thank_you" do
    expect(get("/petitions/thank-you")).to route_to(controller: "petitions", action: "thank_you")
    expect(thank_you_petitions_path).to eq("/petitions/thank-you")
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

  it "routes GET /petitions/start to petitions#start" do
    expect(get("/petitions/start")).to route_to(controller: "petitions", action: "start")
    expect(start_petitions_path).to eq("/petitions/start")
  end

  it "routes GET /petitions/:id/count to petitions#count" do
    expect(get("/petitions/1/count")).to route_to(controller: "petitions", action: "count", id: "1")
    expect(count_petition_path("1")).to eq("/petitions/1/count")
  end

  it "routes GET /petitions/:id/gathering-support to petitions#gathering_support" do
    expect(get("/petitions/1/gathering-support")).to route_to(controller: "petitions", action: "gathering_support", id: "1")
    expect(gathering_support_petition_path("1")).to eq("/petitions/1/gathering-support")
  end

  it "routes GET /petitions/:id/moderation-info to petitions#moderation_info" do
    expect(get("/petitions/1/moderation-info")).to route_to(controller: "petitions", action: "moderation_info", id: "1")
    expect(moderation_info_petition_path("1")).to eq("/petitions/1/moderation-info")
  end
end
