require 'rails_helper'

RSpec.describe "pages", type: :routes do
  describe "English", english: true do
    describe "routes" do
      it "GET / routes to pages#index" do
        expect(get("/")).to route_to(controller: "pages", action: "index")
      end

      it "GET /help routes to pages#help" do
        expect(get("/help")).to route_to(controller: "pages", action: "help")
      end

      it "GET /privacy routes to pages#privacy" do
        expect(get("/privacy")).to route_to(controller: "pages", action: "privacy")
      end
    end

    describe "redirects" do
      it "GET /preifatrwydd" do
        expect(get("/preifatrwydd")).to redirect_to("/privacy", 308)
      end
    end

    describe "helpers" do
      it "#home_url generates https://petitions.senedd.wales/" do
        expect(home_url).to eq("https://petitions.senedd.wales/")
      end

      it "#help_url generates https://petitions.senedd.wales/help" do
        expect(help_url).to eq("https://petitions.senedd.wales/help")
      end

      it "#privacy_url generates https://petitions.senedd.wales/privacy" do
        expect(privacy_url).to eq("https://petitions.senedd.wales/privacy")
      end
    end
  end

  describe "Welsh", welsh: true do
    describe "routes" do
      it "GET / routes to pages#index" do
        expect({:get => "/"}).to route_to(controller: "pages", action: "index")
      end

      it "GET /help routes to pages#help" do
        expect({:get => "/help"}).to route_to(controller: "pages", action: "help")
      end

      it "GET /preifatrwydd routes to pages#privacy" do
        expect({:get => "/preifatrwydd"}).to route_to(controller: "pages", action: "privacy")
      end
    end

    describe "redirects" do
      it "GET /privacy" do
        expect(get("/privacy")).to redirect_to("/preifatrwydd", 308)
      end
    end

    describe "helpers" do
      it "#home_url generates https://deisebau.senedd.cymru/" do
        expect(home_url).to eq("https://deisebau.senedd.cymru/")
      end

      it "#help_url generates https://deisebau.senedd.cymru/help" do
        expect(help_url).to eq("https://deisebau.senedd.cymru/help")
      end

      it "#privacy_url generates https://deisebau.senedd.cymru/preifatrwydd" do
        expect(privacy_url).to eq("https://deisebau.senedd.cymru/preifatrwydd")
      end
    end
  end
end
