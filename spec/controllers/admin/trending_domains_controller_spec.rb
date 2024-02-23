require 'rails_helper'

RSpec.describe Admin::TrendingDomainsController, type: :controller, admin: true do
  context "when not logged in" do
    describe "GET /admin/petitions/200000/trending-domains" do
      before do
        get :index, params: { petition_id: "200000" }
      end

      it "redirects to the login page" do
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end
  end

  context "when logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }

    let(:petition) { double(Petition) }
    let(:scope)  { double(Petition.all) }
    let(:trending_domains) { double(TrendingDomain.all) }

    before do
      login_as(user)
    end

    describe "GET /admin/petitions/200000/trending-domains" do
      before do
        allow(Petition).to receive(:find).with("200000").and_return(petition)
        allow(petition).to receive(:trending_domains).and_return(scope)
      end

      shared_examples_for "trending domains index page" do
        it "responds successfully" do
          expect(response).to be_successful
        end

        it "assigns the @petition instance variable" do
          expect(assigns(:petition)).to eq(petition)
        end

        it "assigns the @trending_domains instance variable" do
          expect(assigns(:trending_domains)).to eq(trending_domains)
        end

        it "renders the trending_domains/index template" do
          expect(response).to render_template("trending_domains/index")
        end
      end

      context "when viewing all trending domains" do
        before do
          expect(scope).to receive(:search).with(nil, page: nil).and_return(trending_domains)
          get :index, params: { petition_id: "200000" }
        end

        include_examples("trending domains index page")
      end

      context "when viewing page 2 of all trending domains" do
        before do
          expect(scope).to receive(:search).with(nil, page: "2").and_return(trending_domains)
          get :index, params: { petition_id: "200000", page: "2" }
        end

        include_examples("trending domains index page")
      end

      context "when searching trending domains" do
        before do
          expect(scope).to receive(:search).with("example.com", page: nil).and_return(trending_domains)
          get :index, params: { petition_id: "200000", q: "example.com" }
        end

        include_examples("trending domains index page")
      end

      context "when viewing page 2 of a trending domains search" do
        before do
          expect(scope).to receive(:search).with("example.com", page: "2").and_return(trending_domains)
          get :index, params: { petition_id: "200000", q: "example.com", page: "2" }
        end

        include_examples("trending domains index page")
      end
    end
  end
end
