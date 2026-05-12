require 'rails_helper'

RSpec.describe 'HTTP Caching', type: :request do
  let(:cache_control) { response.headers["Cache-Control"] }
  let(:status) { response.status }

  let!(:parliament) { FactoryBot.create(:parliament, :coalition) }
  let!(:constituency) { FactoryBot.create(:constituency, :london_and_westminster) }

  before do
    stub_api_request_for("SW1A0AA").to_return(api_response(:ok, "london_and_westminster"))
    stub_api_request_for("BT69GN").to_return(api_response(:ok, "belfast"))

    Site.enable_signature_counts!(interval: 10.seconds)
  end

  shared_examples "is cached for" do |max_age|
    it "is cached for #{max_age.inspect}" do
      expect(cache_control).to match(/max-age=#{max_age}/)
      expect(cache_control).to match(/public/)
      expect(cache_control).to match(/stale-while-revalidate=#{max_age * 2}/)
      expect(cache_control).to match(/stale-if-error=#{max_age * 5}/)
    end
  end

  describe "/" do
    before do
      get "/"
    end

    include_examples "is cached for", 10.seconds
  end

  %w[
    /accessibility
    /cookies
    /help
    /privacy
    /standards
  ].each do |url|
    describe url do
      before do
        get url
      end

      include_examples "is cached for", 1.minute
    end
  end

  describe "/manifest.json" do
    before do
      get "/manifest.json"
    end

    include_examples "is cached for", 5.minutes
  end

  %w[
    /petitions/local
    /petitions/local?postcode=BT6+9GN
  ].each do |url|
    describe url do
      before do
        get url
      end

      include_examples "is cached for", 5.minutes
    end
  end

  %w[
    /petitions/local/cities-of-london-and-westminster
    /petitions/local/cities-of-london-and-westminster/all
  ].each do |url|
    describe url do
      before do
        get url
      end

      include_examples "is cached for", 10.seconds
    end
  end

  %w[
    /constituencies.json
    /parliaments.json
    /parliaments/2010-2015.json
    /topics.json
  ].each do |url|
    describe url do
      before do
        get url
      end

      include_examples "is cached for", 1.minute
    end
  end

  describe "/trending.json" do
    before do
      get "/trending.json"
    end

    include_examples "is cached for", 10.seconds
  end

  describe "/petitions/start" do
    before do
      get "/petitions/start"
    end

    include_examples "is cached for", 5.minutes
  end

  describe "/petitions/:id" do
    let(:petition) { FactoryBot.create(:open_petition) }

    before do
      get "/petitions/#{petition.id}"
    end

    include_examples "is cached for", 10.seconds
  end

  describe "/petitions/:id.json" do
    let(:petition) { FactoryBot.create(:open_petition) }

    before do
      get "/petitions/#{petition.id}.json"
    end

    include_examples "is cached for", 10.seconds
  end

  describe "/petitions/:id/count.json" do
    let(:petition) { FactoryBot.create(:open_petition) }

    before do
      get "/petitions/#{petition.id}/count.json"
    end

    include_examples "is cached for", 10.seconds
  end

  describe "/archived/petitions/:id" do
    let(:petition) { FactoryBot.create(:archived_petition, parliament: parliament) }

    before do
      get "/archived/petitions/#{petition.id}"
    end

    include_examples "is cached for", 2.minutes
  end

  describe "/archived/petitions/:id.json" do
    let(:petition) { FactoryBot.create(:archived_petition, parliament: parliament) }

    before do
      get "/archived/petitions/#{petition.id}.json"
    end

    include_examples "is cached for", 2.minutes
  end
end
