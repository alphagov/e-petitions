require 'rails_helper'

RSpec.describe "routes for admin petition notes", type: :routes, admin: true do
  it "doesn't route GET /admin/petitions/1/notes/new" do
    expect(get("/admin/petitions/1/notes/new")).not_to be_routable
  end

  it "doesn't route POST /admin/petitions/1/notes" do
    expect(post("/admin/petitions/1/notes")).not_to be_routable
  end

  it "routes GET /admin/petitions/1/notes to admin/notes#show" do
    expect(get("/admin/petitions/1/notes")).to route_to('admin/notes#show', petition_id: '1')
  end

  it "doesn't route GET /admin/petitions/1/notes/edit" do
    expect(post("/admin/petitions/1/notes/edit")).not_to be_routable
  end

  it "routes PATCH /admin/petitions/1/notes to admin/notes#update" do
    expect(patch("/admin/petitions/1/notes")).to route_to('admin/notes#update', petition_id: '1')
  end

  it "doesn't route DELETE /admin/petitions/1/notes" do
    expect(delete("/admin/petitions/1/notes")).not_to be_routable
  end
end
