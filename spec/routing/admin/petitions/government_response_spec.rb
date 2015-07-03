require 'rails_helper'

RSpec.describe "routes for admin petition government response", type: :routes, admin: true do
  it "doesn't route GET /admin/petitions/1/government-response/new" do
    expect(get("/admin/petitions/1/government-response/new")).not_to be_routable
  end

  it "doesn't route POST /admin/petitions/1/government-response" do
    expect(post("/admin/petitions/1/government-response")).not_to be_routable
  end

  it "routes GET /admin/petitions/1/government-response to admin/government_response#show" do
    expect(get("/admin/petitions/1/government-response")).to route_to('admin/government_response#show', petition_id: '1')
  end

  it "doesn't route GET /admin/petitions/1/government-response/edit" do
    expect(post("/admin/petitions/1/notes/edit")).not_to be_routable
  end

  it "routes PATCH /admin/petitions/1/government-response to admin/government_response#update" do
    expect(patch("/admin/petitions/1/government-response")).to route_to('admin/government_response#update', petition_id: '1')
  end

  it "doesn't route DELETE /admin/petitions/1/government-response" do
    expect(delete("/admin/petitions/1/government-response")).not_to be_routable
  end
end
