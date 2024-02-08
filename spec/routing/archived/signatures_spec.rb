require 'rails_helper'

RSpec.describe "routes for archived signatures", type: :routes do
  # Routes nested to /archived/petition/:petition_id
  it "doesn't route GET /archived/petitions/1/signatures" do
    expect(get("/archived/petitions/1/signatures")).not_to be_routable
  end

  it "doesn't route GET /archived/petitions/1/signatures/new" do
    expect(get("/archived/petitions/1/signatures/new")).not_to be_routable
  end

  it "doesn't route POST /archived/petitions/1/signatures/new" do
    expect(post("/archived/petitions/1/signatures/new")).not_to be_routable
  end

  it "doesn't route POST /archived/petitions/1/signatures" do
    expect(post("/archived/petitions/1/signatures")).not_to be_routable
  end

  it "doesn't route GET /archived/petitions/1/signatures/thank-you" do
    expect(get("/archived/petitions/1/signatures/thank-you")).not_to be_routable
  end

  it "doesn't route GET /archived/petitions/1/signatures/2" do
    expect(post("/archived/petitions/1/signatures/2")).not_to be_routable
  end

  it "doesn't route GET /archived/petitions/1/signatures/2/edit" do
    expect(post("/archived/petitions/1/signatures/2/edit")).not_to be_routable
  end

  it "doesn't route PATCH /archived/petitions/1/signatures/2" do
    expect(patch("/archived/petitions/1/signatures/2")).not_to be_routable
  end

  it "doesn't route PUT /archived/petitions/1/signatures/2" do
    expect(put("/archived/petitions/1/signatures/2")).not_to be_routable
  end

  it "doesn't route DELETE /archived/petitions/1/signatures/2" do
    expect(delete("/archived/petitions/1/signatures/2")).not_to be_routable
  end

  # un-nested routes
  it "doesn't route GET /archived/signatures/:id/verify" do
    expect(get("/archived/signatures/1/verify?token=abcdef1234567890")).not_to be_routable
  end

  it "routes GET /archived/signatures/:id/unsubscribe to archived/signatures#unsubscribe" do
    expect(get("/archived/signatures/1/unsubscribe?token=abcdef1234567890")).
      to route_to("archived/signatures#unsubscribe", id: "1", token: "abcdef1234567890")

    expect(unsubscribe_archived_signature_path("1", token: "abcdef1234567890")).
      to eq("/archived/signatures/1/unsubscribe?token=abcdef1234567890")
  end

  it "routes POST /archived/signatures/:id/unsubscribe to archived/signatures#unsubscribe" do
    expect(post("/archived/signatures/1/unsubscribe?token=abcdef1234567890")).
      to route_to("archived/signatures#unsubscribe", id: "1", token: "abcdef1234567890")
  end

  it "doesn't route GET /archived/signatures/:id/signed" do
    expect(get("/archived/signatures/1/signed?token=abcdef1234567890")).not_to be_routable
  end

  it "doesn't route GET /archived/signatures" do
    expect(get("/archived/signatures")).not_to be_routable
  end

  it "doesn't route GET /archived/signatures/new" do
    expect(get("/archived/signatures/new")).not_to be_routable
  end

  it "doesn't route POST /archived/signatures" do
    expect(post("/archived/signatures")).not_to be_routable
  end

  it "doesn't route GET /archived/signatures/1" do
    expect(post("/archived/signatures/2")).not_to be_routable
  end

  it "doesn't route GET /archived/signatures/1/edit" do
    expect(post("/archived/signatures/2/edit")).not_to be_routable
  end

  it "doesn't route PATCH /archived/signatures/1" do
    expect(patch("/archived/signatures/2")).not_to be_routable
  end

  it "doesn't route DELETE /archived/signatures/1" do
    expect(delete("/archived/signatures/2")).not_to be_routable
  end
end
