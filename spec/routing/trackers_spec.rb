require 'rails_helper'

RSpec.describe "routes for tracker", type: :routes do
  it "doesn't route GET /petitions/:petition_id/trackers" do
    expect(get("/petitions/1/trackers")).not_to be_routable
  end

  it "doesn't route GET /petitions/:petition_id/trackers/new" do
    expect(get("/petitions/1/trackers/new")).not_to be_routable
  end

  it "doesn't route POST /petitions/:petition_id/trackers" do
    expect(post("/petitions/1/trackers")).not_to be_routable
  end

  it "doesn't route GET /petitions/:petition_id/trackers/:id" do
    expect(post("/petitions/1/trackers/S7lqpOv8zEvROaq3bJE8")).not_to be_routable
  end

  it "doesn't route GET /petitions/:petition_id/trackers/:id.html" do
    expect(post("/petitions/1/trackers/S7lqpOv8zEvROaq3bJE8.html")).not_to be_routable
  end

  it "routes GET /petitions/:petition_id/trackers/:id.gif to trackers#show" do
    expect(get("/petitions/1/trackers/S7lqpOv8zEvROaq3bJE8.gif")).
      to route_to("trackers#show", petition_id: "1", id: "S7lqpOv8zEvROaq3bJE8")

    expect(petition_tracker_path("1", "S7lqpOv8zEvROaq3bJE8", :gif)).to eq("/petitions/1/trackers/S7lqpOv8zEvROaq3bJE8.gif")
  end

  it "doesn't route GET /petitions/:petition_id/trackers/:id/edit" do
    expect(post("/petitions/1/trackers/S7lqpOv8zEvROaq3bJE8/edit")).not_to be_routable
  end

  it "doesn't route PATCH /petitions/:petition_id/trackers/:id" do
    expect(patch("/petitions/1/trackers/S7lqpOv8zEvROaq3bJE8")).not_to be_routable
  end

  it "doesn't route DELETE /petitions/:petition_id/trackers/:id" do
    expect(delete("/petitions/1/trackers/S7lqpOv8zEvROaq3bJE8")).not_to be_routable
  end
end
