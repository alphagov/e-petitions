require 'rails_helper'

RSpec.describe "routes for sponsor", type: :routes do
  # Routes nested to /petition/:petition_id
  it "doesn't route GET /petitions/1/sponsors" do
    expect(get("/petitions/1/sponsors")).not_to be_routable
  end

  it "routes GET /petitions/1/sponsors/new to sponsors#new" do
    expect(get("/petitions/1/sponsors/new")).to route_to("sponsors#new", petition_id: "1")
  end

  it "routes POST /petitions/1/sponsors/new to sponsors#create" do
    expect(post("/petitions/1/sponsors/new")).to route_to("sponsors#create", petition_id: "1")
  end

  it "doesn't route POST /petitions/1/sponsors" do
    expect(post("/petitions/1/sponsors")).not_to be_routable
  end

  it "routes GET /petitions/1/sponsors/thank-you to sponsors#thank_you" do
    expect(get("/petitions/1/sponsors/thank-you")).to route_to("sponsors#thank_you", petition_id: "1")
  end

  it "doesn't route GET /petitions/1/sponsors/2" do
    expect(post("/petitions/1/sponsors/2")).not_to be_routable
  end

  it "doesn't route GET /petitions/1/sponsors/2/edit" do
    expect(post("/petitions/1/sponsors/2/edit")).not_to be_routable
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
  it "routes GET /sponsors/:id/verify to sponsors#verify" do
    expect(get("/sponsors/1/verify?token=abcdef1234567890")).
      to route_to("sponsors#verify", id: "1", token: "abcdef1234567890")

    expect(verify_sponsor_path("1", token: "abcdef1234567890")).to eq("/sponsors/1/verify?token=abcdef1234567890")
  end

  it "doesn't route GET /sponsors/:id/unsubscribe" do
    expect(delete("/sponsors/1/unsubscribe")).not_to be_routable
  end

  it "routes GET /sponsors/:id/sponsored to sponsors#signed" do
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
    expect(post("/sponsors/2")).not_to be_routable
  end

  it "doesn't route GET /sponsors/1/edit" do
    expect(post("/sponsors/2/edit")).not_to be_routable
  end

  it "doesn't route PATCH /sponsors/1" do
    expect(patch("/sponsors/2")).not_to be_routable
  end

  it "doesn't route DELETE /sponsors/1" do
    expect(delete("/sponsors/2")).not_to be_routable
  end
end
