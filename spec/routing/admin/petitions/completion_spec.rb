require 'rails_helper'

RSpec.describe "routes for admin petition complettion", type: :routes, admin: true do
  it "doesn't route GET /admin/petitions/1/completion/new" do
    expect(get("/admin/petitions/1/completion/new")).not_to be_routable
  end

  it "doesn't route POST /admin/petitions/1/completion" do
    expect(post("/admin/petitions/1/completion")).not_to be_routable
  end

  it "doesn't route GET /admin/petitions/1/completion" do
    expect(get("/admin/petitions/1/completion")).not_to be_routable
  end

  it "doesn't route GET /admin/petitions/1/completion/edit" do
    expect(post("/admin/petitions/1/completion/edit")).not_to be_routable
  end

  it "routes PATCH /admin/petitions/1/completion to admin/completion#update" do
    expect(patch("/admin/petitions/1/completion")).to route_to('admin/completion#update', petition_id: '1')
  end

  it "doesn't route DELETE /admin/petitions/1/completion" do
    expect(delete("/admin/petitions/1/completion")).not_to be_routable
  end
end
