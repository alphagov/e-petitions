require 'rails_helper'

RSpec.describe 'Link header', type: :request do
  let(:link_header) { response.headers['Link'] }
  let(:status) { response.status }

  context "when visiting the home page" do
    before do
      get "/"
    end

    it "sets the correct Link header" do
      expect(status).to eq(200)
      expect(link_header).to be_present
      expect(link_header).to include("</assets/application.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application.js>; rel=preload; as=script; type=text/javascript; nopush")

      expect(link_header).not_to include("</assets/auto-updater.js>; rel=preload; as=script; type=text/javascript; nopush")
      expect(link_header).not_to include("</assets/character-counter.js>; rel=preload; as=script; type=text/javascript; nopush")
    end
  end

  context "when visiting the help page" do
    before do
      get "/help"
    end

    it "sets the correct Link header" do
      expect(status).to eq(200)
      expect(link_header).to be_present
      expect(link_header).to include("</assets/application.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application.js>; rel=preload; as=script; type=text/javascript; nopush")

      expect(link_header).not_to include("</assets/auto-updater.js>; rel=preload; as=script; type=text/javascript; nopush")
      expect(link_header).not_to include("</assets/character-counter.js>; rel=preload; as=script; type=text/javascript; nopush")
    end
  end

  context "when visiting the check petition page" do
    before do
      get "/petitions/check"
    end

    it "sets the correct Link header" do
      expect(status).to eq(200)
      expect(link_header).to be_present
      expect(link_header).to include("</assets/application.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application.js>; rel=preload; as=script; type=text/javascript; nopush")

      expect(link_header).not_to include("</assets/auto-updater.js>; rel=preload; as=script; type=text/javascript; nopush")
      expect(link_header).to include("</assets/character-counter.js>; rel=preload; as=script; type=text/javascript; nopush")
    end
  end

  context "when visiting an open petition page" do
    let!(:petition) { FactoryBot.create(:open_petition) }

    before do
      get "/petitions/#{petition.id}"
    end

    it "sets the correct Link header" do
      expect(status).to eq(200)
      expect(link_header).to be_present
      expect(link_header).to include("</assets/application.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application.js>; rel=preload; as=script; type=text/javascript; nopush")

      expect(link_header).to include("</assets/auto-updater.js>; rel=preload; as=script; type=text/javascript; nopush")
      expect(link_header).not_to include("</assets/character-counter.js>; rel=preload; as=script; type=text/javascript; nopush")
    end
  end

  context "when visiting a closed petition page" do
    let!(:petition) { FactoryBot.create(:closed_petition) }

    before do
      get "/petitions/#{petition.id}"
    end

    it "sets the correct Link header" do
      expect(status).to eq(200)
      expect(link_header).to be_present
      expect(link_header).to include("</assets/application.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application.js>; rel=preload; as=script; type=text/javascript; nopush")

      expect(link_header).not_to include("</assets/auto-updater.js>; rel=preload; as=script; type=text/javascript; nopush")
      expect(link_header).not_to include("</assets/character-counter.js>; rel=preload; as=script; type=text/javascript; nopush")
    end
  end

  context "when visiting an archived petition page" do
    let!(:petition) { FactoryBot.create(:archived_petition) }

    before do
      get "/archived/petitions/#{petition.id}"
    end

    it "sets the correct Link header" do
      expect(status).to eq(200)
      expect(link_header).to be_present
      expect(link_header).to include("</assets/application.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application.js>; rel=preload; as=script; type=text/javascript; nopush")

      expect(link_header).not_to include("</assets/auto-updater.js>; rel=preload; as=script; type=text/javascript; nopush")
      expect(link_header).not_to include("</assets/character-counter.js>; rel=preload; as=script; type=text/javascript; nopush")
    end
  end
end
