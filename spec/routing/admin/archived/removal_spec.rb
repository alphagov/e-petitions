require 'rails_helper'

RSpec.describe "routes for admin archived petition removal", type: :routes, admin: true do
  it "doesn't route GET /admin/archived/petitions/1/removal/new" do
    expect(get("/admin/archived/petitions/1/removal/new")).not_to be_routable
  end

  it "doesn't route POST /admin/archived/petitions/1/removal" do
    expect(post("/admin/archived/petitions/1/removal")).not_to be_routable
  end

  it "routes GET /admin/archived/petitions/1/removal to admin/archived/petition_removals#show" do
    expect(get("/admin/archived/petitions/1/removal")).to route_to('admin/archived/petition_removals#show', petition_id: '1')
  end

  it "doesn't route GET /admin/archived/petitions/1/removal/edit" do
    expect(post("/admin/archived/petitions/1/removal/edit")).not_to be_routable
  end

  it "routes PATCH /admin/archived/petitions/1/removal to admin/archived/petition_removals#update" do
    expect(patch("/admin/archived/petitions/1/removal")).to route_to('admin/archived/petition_removals#update', petition_id: '1')
  end

  it "doesn't route DELETE /admin/archived/petitions/1/removal" do
    expect(delete("/admin/archived/petitions/1/removal")).not_to be_routable
  end
end
