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
      expect(link_header).to include("</assets/application-99b2f534.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application-a5386140.js>; rel=preload; as=script; type=text/javascript; nopush")
    end
  end

  context "when visiting the help page" do
    let!(:page) { FactoryBot.create(:page, :help) }

    before do
      get "/help"
    end

    it "sets the correct Link header" do
      expect(status).to eq(200)
      expect(link_header).to be_present
      expect(link_header).to include("</assets/application-99b2f534.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application-a5386140.js>; rel=preload; as=script; type=text/javascript; nopush")
    end
  end

  context "when visiting the start petition page" do
    before do
      get "/petitions/start"
    end

    it "sets the correct Link header" do
      expect(status).to eq(200)
      expect(link_header).to be_present
      expect(link_header).to include("</assets/application-99b2f534.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application-a5386140.js>; rel=preload; as=script; type=text/javascript; nopush")
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
      expect(link_header).to include("</assets/application-99b2f534.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application-a5386140.js>; rel=preload; as=script; type=text/javascript; nopush")
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
      expect(link_header).to include("</assets/application-99b2f534.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application-a5386140.js>; rel=preload; as=script; type=text/javascript; nopush")
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
      expect(link_header).to include("</assets/application-99b2f534.css>; rel=preload; as=style; type=text/css; nopush")
      expect(link_header).to include("</assets/application-a5386140.js>; rel=preload; as=script; type=text/javascript; nopush")
    end
  end
end
