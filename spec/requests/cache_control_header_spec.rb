require 'rails_helper'

RSpec.describe 'Cache-Control headers', type: :request do
  let(:cache_control) { response.headers['Cache-Control'] }
  let(:status) { response.status }

  context "when visiting the petition index page" do
    before do
      get "/petitions"
    end

    it "doesn't change the cache control headers" do
      expect(cache_control).to eq("max-age=0, private, must-revalidate")
      expect(status).to eq(200)
    end
  end

  context "when visiting the petition show page" do
    let!(:petition) { FactoryGirl.create(:open_petition) }

    before do
      get "/petitions/#{petition.id}"
    end

    it "doesn't change the cache control headers" do
      expect(cache_control).to eq("max-age=0, private, must-revalidate")
      expect(status).to eq(200)
    end
  end

  context "when visiting the new petition page" do
    let!(:petition) { FactoryGirl.create(:open_petition) }

    before do
      get "/petitions/new"
    end

    it "changes the cache control headers to 'no-store, no-cache'" do
      expect(cache_control).to eq("no-store, no-cache")
      expect(status).to eq(200)
    end
  end

  context "when visiting the new sponsor page" do
    let!(:petition) { FactoryGirl.create(:pending_petition) }

    before do
      get "/petitions/#{petition.id}/sponsors/#{petition.sponsor_token}"
    end

    it "changes the cache control headers to 'no-store, no-cache'" do
      expect(cache_control).to eq("no-store, no-cache")
      expect(status).to eq(200)
    end
  end

  context "when visiting the new signature page" do
    let!(:petition) { FactoryGirl.create(:open_petition) }

    before do
      get "/petitions/#{petition.id}/signatures/new"
    end

    it "changes the cache control headers to 'no-store, no-cache'" do
      expect(cache_control).to eq("no-store, no-cache")
      expect(status).to eq(200)
    end
  end

  context "when visiting an admin page", admin: true do
    before do
      get "/admin/login"
    end

    it "changes the cache control headers to 'no-store, no-cache'" do
      expect(cache_control).to eq("no-store, no-cache")
      expect(status).to eq(200)
    end
  end
end
