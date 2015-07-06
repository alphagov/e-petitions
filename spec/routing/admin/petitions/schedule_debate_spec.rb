require 'rails_helper'

RSpec.describe "routes for admin petition scheduled debate dates", type: :routes, admin: true do
  it "doesn't route GET /admin/petitions/1/schedule-debate/new" do
    expect(get("/admin/petitions/1/schedule-debate/new")).not_to be_routable
  end

  it "doesn't route POST /admin/petitions/1/schedule-debate" do
    expect(post("/admin/petitions/1/schedule-debate")).not_to be_routable
  end

  it "routes GET /admin/petitions/1/schedule-debate to admin/schedule_debate#show" do
    expect(get("/admin/petitions/1/schedule-debate")).to route_to('admin/schedule_debate#show', petition_id: '1')
  end

  it "doesn't route GET /admin/petitions/1/schedule-debate/edit" do
    expect(post("/admin/petitions/1/schedule-debate/edit")).not_to be_routable
  end

  it "routes PATCH /admin/petitions/1/schedule-debate to admin/schedule_debate#update" do
    expect(patch("/admin/petitions/1/schedule-debate")).to route_to('admin/schedule_debate#update', petition_id: '1')
  end

  it "doesn't route DELETE /admin/petitions/1/schedule-debate" do
    expect(delete("/admin/petitions/1/schedule-debate")).not_to be_routable
  end
end
