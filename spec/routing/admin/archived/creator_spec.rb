require 'rails_helper'

RSpec.describe "routes for admin archived petition creator", type: :routes, admin: true do
  it "doesn't route GET /admin/archived/petitions/1/creator/new" do
    expect(get("/admin/archived/petitions/1/creator/new")).not_to be_routable
  end

  it "doesn't route POST /admin/archived/petitions/1/creator" do
    expect(post("/admin/archived/petitions/1/creator")).not_to be_routable
  end

  it "doesn't route GET /admin/archived/petitions/1/creator" do
    expect(get("/admin/archived/petitions/1/creator")).not_to be_routable
  end

  it "doesn't route GET /admin/archived/petitions/1/creator/edit" do
    expect(post("/admin/archived/petitions/1/creator/edit")).not_to be_routable
  end

  it "doesn't route PATCH /admin/archived/petitions/1/creator" do
    expect(patch("/admin/archived/petitions/1/creator")).not_to be_routable
  end

  it "routes DELETE /admin/archived/petitions/1/creator to admin/creators#destroy" do
    expect(delete("/admin/archived/petitions/1/creator")).to route_to('admin/archived/creators#destroy', petition_id: '1')
  end
end
