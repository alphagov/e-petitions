require 'rails_helper'

RSpec.describe "routes for admin petitions", type: :routing do
  it "routes GET /admin/petitions/ to admin/petitions#index" do
    expect(get("/admin/petitions")).to route_to('admin/petitions#index')
  end

  it "doesn't route GET /admin/petitions/1/new" do
    expect(get("/admin/petitions/1/new")).not_to be_routable
  end

  it "doesn't route POST /admin/petitions/1" do
    expect(post("/admin/petitions/1")).not_to be_routable
  end

  it "routes GET /admin/petitions/1 to admin/petitions#show" do
    expect(get("/admin/petitions/1")).to route_to('admin/petitions#show', id: '1')
  end

  it "doesn't route GET /admin/petitions/1/edit" do
    expect(post("/admin/petitions/1/edit")).not_to be_routable
  end

  it "doesn't route PATCH /admin/petitions/1" do
    expect(patch("/admin/petitions/1")).not_to be_routable
  end

  it "doesn't route DELETE /admin/petitions/1" do
    expect(delete("/admin/petitions/1")).not_to be_routable
  end

  it "routes GET /admin/petitions/1 to admin/petitions#show" do
    expect(get("/admin/petitions/threshold")).to route_to('admin/petitions#threshold')
  end

  it "routes GET /admin/petitions/1/edit_response to admin/petitions#edit_response" do
    expect(get("/admin/petitions/1/edit_response")).to route_to('admin/petitions#edit_response', id: '1')
  end

  it "routes PATCH /admin/petitions/1/update_response to admin/petitions#update_response" do
    expect(patch("/admin/petitions/1/update_response")).to route_to('admin/petitions#update_response', id: '1')
  end

  it "routes GET /admin/petitions/1/edit_scheduled_debate_date to admin/petitions#edit_scheduled_debate_date" do
    expect(get("/admin/petitions/1/edit_scheduled_debate_date")).to route_to('admin/petitions#edit_scheduled_debate_date', id: '1')
  end

  it "routes PATCH /admin/petitions/1/update_scheduled_debate_date to admin/petitions#update_scheduled_debate_date" do
    expect(patch("/admin/petitions/1/update_scheduled_debate_date")).to route_to('admin/petitions#update_scheduled_debate_date', id: '1')
  end

  it "routes PATCH /admin/petitions/1/take_down to admin/petitions#take_down" do
    expect(patch("/admin/petitions/1/take_down")).to route_to('admin/petitions#take_down', id: '1')
  end
end
