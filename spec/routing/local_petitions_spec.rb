require 'rails_helper'

RSpec.describe "routes for local petitions", type: :routing do
  it "routes GET /petitions/local to local_petitions#index" do
    expect(get("/petitions/local")).to route_to("local_petitions#index")
  end
end
