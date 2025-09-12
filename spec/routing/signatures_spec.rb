require 'rails_helper'

RSpec.describe "routes for signatures", type: :routes do
  # Routes nested to /petition/:petition_id
  it "doesn't route GET /petitions/1/signatures" do
    expect(get("/petitions/1/signatures")).not_to be_routable
  end

  it "routes GET /petitions/1/signatures/new to signatures#new" do
    expect(get("/petitions/1/signatures/new")).to route_to("signatures#new", petition_id: "1")
  end

  it "routes POST /petitions/1/signatures/new to signatures#create" do
    expect(post("/petitions/1/signatures/new")).to route_to("signatures#create", petition_id: "1")
  end

  it "doesn't route POST /petitions/1/signatures" do
    expect(post("/petitions/1/signatures")).not_to be_routable
  end

  it "routes GET /petitions/1/signatures/thank-you to signatures#thank_you" do
    expect(get("/petitions/1/signatures/thank-you")).to route_to("signatures#thank_you", petition_id: "1")
  end

  it "doesn't route GET /petitions/1/signatures/2" do
    expect(post("/petitions/1/signatures/2")).not_to be_routable
  end

  it "doesn't route GET /petitions/1/signatures/2/edit" do
    expect(post("/petitions/1/signatures/2/edit")).not_to be_routable
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
  it "routes GET /signatures/:id/verify to signatures#verify" do
    expect(get("/signatures/1/verify?token=abcdef1234567890")).
      to route_to("signatures#verify", id: "1", token: "abcdef1234567890")

    expect(verify_signature_path("1", token: "abcdef1234567890")).to eq("/signatures/1/verify?token=abcdef1234567890")
  end

  it "routes GET /signatures/:id/unsubscribe to signatures#unsubscribe" do
    expect(get("/signatures/1/unsubscribe?token=abcdef1234567890")).
      to route_to("signatures#unsubscribe", id: "1", token: "abcdef1234567890")

    expect(unsubscribe_signature_path("1", token: "abcdef1234567890")).to eq("/signatures/1/unsubscribe?token=abcdef1234567890")
  end

  it "routes POST /signatures/:id/unsubscribe to signatures#unsubscribe" do
    expect(post("/signatures/1/unsubscribe?token=abcdef1234567890")).
      to route_to("signatures#unsubscribe", id: "1", token: "abcdef1234567890")
  end

  it "routes GET /signatures/:id/signed to signatures#signed" do
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
    expect(post("/signatures/2")).not_to be_routable
  end

  it "doesn't route GET /signatures/1/edit" do
    expect(post("/signatures/2/edit")).not_to be_routable
  end

  it "doesn't route PATCH /signatures/1" do
    expect(patch("/signatures/2")).not_to be_routable
  end

  it "doesn't route DELETE /signatures/1" do
    expect(delete("/signatures/2")).not_to be_routable
  end
end
