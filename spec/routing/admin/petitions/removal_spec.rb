require 'rails_helper'

RSpec.describe "routes for admin petition removal", type: :routes, admin: true do
  it "doesn't route GET /admin/petitions/1/removal/new" do
    expect(get("/admin/petitions/1/removal/new")).not_to be_routable
  end

  it "doesn't route POST /admin/petitions/1/removal" do
    expect(post("/admin/petitions/1/removal")).not_to be_routable
  end

  it "routes GET /admin/petitions/1/removal to admin/petition_removals#show" do
    expect(get("/admin/petitions/1/removal")).to route_to('admin/petition_removals#show', petition_id: '1')
  end

  it "doesn't route GET /admin/petitions/1/removal/edit" do
    expect(post("/admin/petitions/1/removal/edit")).not_to be_routable
  end

  it "routes PATCH /admin/petitions/1/removal to admin/petition_removals#update" do
    expect(patch("/admin/petitions/1/removal")).to route_to('admin/petition_removals#update', petition_id: '1')
  end

  it "doesn't route DELETE /admin/petitions/1/removal" do
    expect(delete("/admin/petitions/1/removal")).not_to be_routable
  end
end
