require 'rails_helper'

RSpec.describe "routes for admin petition creator", type: :routes, admin: true do
  it "doesn't route GET /admin/petitions/1/creator/new" do
    expect(get("/admin/petitions/1/creator/new")).not_to be_routable
  end

  it "doesn't route POST /admin/petitions/1/creator" do
    expect(post("/admin/petitions/1/creator")).not_to be_routable
  end

  it "doesn't route GET /admin/petitions/1/creator" do
    expect(get("/admin/petitions/1/creator")).not_to be_routable
  end

  it "doesn't route GET /admin/petitions/1/creator/edit" do
    expect(post("/admin/petitions/1/creator/edit")).not_to be_routable
  end

  it "doesn't route PATCH /admin/petitions/1/creator" do
    expect(patch("/admin/petitions/1/creator")).not_to be_routable
  end

  it "routes DELETE /admin/petitions/1/creator to admin/creators#destroy" do
    expect(delete("/admin/petitions/1/creator")).to route_to('admin/creators#destroy', petition_id: '1')
  end
end
