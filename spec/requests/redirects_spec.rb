require 'rails_helper'

RSpec.describe "Trying to access", type: :request do
  let(:status) { response.status }
  let(:location) { response.location }
  let(:cache_control) { response.cache_control }

  it "the old /departments page redirects to the home page" do
    get "/departments"

    expect(status).to eq(301)
    expect(location).to eq("https://petition.parliament.uk/")
    expect(cache_control).to include(max_age: "3155695200", public: true)
  end

  it "the old /api page redirects to the home page" do
    get "/api/petitions"

    expect(status).to eq(301)
    expect(location).to eq("https://petition.parliament.uk/")
    expect(cache_control).to include(max_age: "3155695200", public: true)
  end

  it "the old /privacy-policy page redirects to the new privacy page" do
    get "/privacy-policy"

    expect(status).to eq(301)
    expect(location).to eq("https://petition.parliament.uk/privacy")
    expect(cache_control).to include(max_age: "3155695200", public: true)
  end

  it "the old /terms-and-conditions page redirects to the help page" do
    get "/terms-and-conditions"

    expect(status).to eq(301)
    expect(location).to eq("https://petition.parliament.uk/help")
    expect(cache_control).to include(max_age: "3155695200", public: true)
  end

  it "the old /help/standards page redirects to the standards page" do
    get "/help/standards"

    expect(status).to eq(301)
    expect(location).to eq("https://petition.parliament.uk/standards")
    expect(cache_control).to include(max_age: "3155695200", public: true)
  end

  it "the old /how-it-works page redirects to the help page" do
    get "/how-it-works"

    expect(status).to eq(301)
    expect(location).to eq("https://petition.parliament.uk/help")
    expect(cache_control).to include(max_age: "3155695200", public: true)
  end

  it "the old /faq page redirects to the help page" do
    get "/faq"

    expect(status).to eq(301)
    expect(location).to eq("https://petition.parliament.uk/help")
    expect(cache_control).to include(max_age: "3155695200", public: true)
  end

  it "the old /crown-copyright page redirects to the National Archives page" do
    get "/crown-copyright"

    expect(status).to eq(301)
    expect(location).to eq("https://www.nationalarchives.gov.uk/information-management/our-services/crown-copyright.htm")
    expect(cache_control).to include(max_age: "3155695200", public: true)
  end
end
