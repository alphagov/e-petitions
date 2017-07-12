require 'rails_helper'

RSpec.describe "routes for petitions", type: :routes do
  it "routes GET /petitions/new to petitions#new" do
    expect({:get => "/petitions/new"}).to route_to({:controller => "petitions", :action => "new"})
    expect(new_petition_path).to eq '/petitions/new'
  end

  it "routes POST /petitions/new to petitions#create" do
    expect({:post => "/petitions/new"}).to route_to({:controller => "petitions", :action => "create"})
    expect(create_petitions_path).to eq('/petitions/new')
  end
end
