require 'rails_helper'

RSpec.describe "routes for admin petition take downs", type: :routing do
  it "doesn't route GET /admin/petitions/1/take_down/new" do
    expect(get("/admin/petitions/1/take-down/new")).not_to be_routable
  end

  it "doesn't route POST /admin/petitions/1/take_down" do
    expect(post("/admin/petitions/1/take-down")).not_to be_routable
  end

  it "routes GET /admin/petitions/1/take-down to admin/take_down#show" do
    expect(get("/admin/petitions/1/take-down")).to route_to('admin/take_down#show', petition_id: '1')
  end

  it "doesn't route GET /admin/petitions/1/take-down/edit" do
    expect(post("/admin/petitions/1/take-down/edit")).not_to be_routable
  end

  it "routes PATCH /admin/petitions/1/take-down to admin/take_down#update" do
    expect(patch("/admin/petitions/1/take-down")).to route_to('admin/take_down#update', petition_id: '1')
  end

  it "doesn't route DELETE /admin/petitions/1/take-down" do
    expect(delete("/admin/petitions/1/take-down")).not_to be_routable
  end
end
