require 'rails_helper'

RSpec.describe "routes for admin petition moderation", type: :routing do
  it "doesn't route GET /admin/petitions/1/moderation/new" do
    expect(get("/admin/petitions/1/moderation/new")).not_to be_routable
  end

  it "doesn't route POST /admin/petitions/1/moderation" do
    expect(post("/admin/petitions/1/moderation")).not_to be_routable
  end

  it "doesn't route GET /admin/petitions/1/moderation" do
    expect(get("/admin/petitions/1/moderation")).not_to be_routable
  end

  it "doesn't route GET /admin/petitions/1/moderation/edit" do
    expect(post("/admin/petitions/1/moderation/edit")).not_to be_routable
  end

  it "routes PATCH /admin/petitions/1/moderation to admin/moderation#update" do
    expect(patch("/admin/petitions/1/moderation")).to route_to('admin/moderation#update', petition_id: '1')
  end

  it "doesn't route DELETE /admin/petitions/1/moderation" do
    expect(delete("/admin/petitions/1/moderation")).not_to be_routable
  end
end
