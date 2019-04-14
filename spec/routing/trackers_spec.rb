require 'rails_helper'

RSpec.describe "routes for tracker", type: :routes do
  it "doesn't route GET /trackers" do
    expect(get("/trackers")).not_to be_routable
  end

  it "doesn't route GET /trackers/new" do
    expect(get("/trackers/new")).not_to be_routable
  end

  it "doesn't route POST /trackers" do
    expect(post("/trackers")).not_to be_routable
  end

  it "doesn't route GET /trackers/S7lqpOv8zEvROaq3bJE8" do
    expect(post("/trackers/S7lqpOv8zEvROaq3bJE8")).not_to be_routable
  end

  it "doesn't route GET /trackers/S7lqpOv8zEvROaq3bJE8.html" do
    expect(post("/trackers/S7lqpOv8zEvROaq3bJE8.html")).not_to be_routable
  end

  it "routes GET /trackers/S7lqpOv8zEvROaq3bJE8.gif to trackers#show" do
    expect(get("/trackers/S7lqpOv8zEvROaq3bJE8.gif")).
      to route_to("trackers#show", id: "S7lqpOv8zEvROaq3bJE8")

    expect(tracker_path("S7lqpOv8zEvROaq3bJE8", :gif)).to eq("/trackers/S7lqpOv8zEvROaq3bJE8.gif")
  end

  it "doesn't route GET /trackers/S7lqpOv8zEvROaq3bJE8/edit" do
    expect(post("/trackers/S7lqpOv8zEvROaq3bJE8/edit")).not_to be_routable
  end

  it "doesn't route PATCH /trackers/S7lqpOv8zEvROaq3bJE8" do
    expect(patch("/trackers/S7lqpOv8zEvROaq3bJE8")).not_to be_routable
  end

  it "doesn't route DELETE /trackers/S7lqpOv8zEvROaq3bJE8" do
    expect(delete("/trackers/S7lqpOv8zEvROaq3bJE8")).not_to be_routable
  end
end
