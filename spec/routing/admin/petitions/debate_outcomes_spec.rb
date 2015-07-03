require 'rails_helper'

RSpec.describe "routes for admin petition debate outcomes", type: :routes, admin: true do
  it "doesn't route GET /admin/petitions/1/debate-outcome/new" do
    expect(get("/admin/petitions/1/debate-outcome/new")).not_to be_routable
  end

  it "doesn't route POST /admin/petitions/1/debate-outcome" do
    expect(post("/admin/petitions/1/debate-outcome")).not_to be_routable
  end

  it "routes GET /admin/petitions/1/debate-outcome to admin/debate_outcomes#show" do
    expect(get("/admin/petitions/1/debate-outcome")).to route_to('admin/debate_outcomes#show', petition_id: '1')
  end

  it "doesn't route GET /admin/petitions/1/debate-outcome/edit" do
    expect(post("/admin/petitions/1/debate-outcome/edit")).not_to be_routable
  end

  it "routes PATCH /admin/petitions/1/debate-outcome to admin/debate_outcomes#update" do
    expect(patch("/admin/petitions/1/debate-outcome")).to route_to('admin/debate_outcomes#update', petition_id: '1')
  end

  it "doesn't route DELETE /admin/petitions/1/debate-outcome" do
    expect(delete("/admin/petitions/1/debate-outcome")).not_to be_routable
  end
end
