require 'rails_helper'

RSpec.describe Admin::TrendingIpsController, type: :controller, admin: true do
  context "when not logged in" do
    describe "GET /admin/petitions/200000/trending-ips" do
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
    let(:trending_ips) { double(TrendingIp.all) }

    before do
      login_as(user)
    end

    describe "GET /admin/petitions/200000/trending-ips" do
      before do
        allow(Petition).to receive(:find).with("200000").and_return(petition)
        allow(petition).to receive(:trending_ips).and_return(scope)
      end

      shared_examples_for "trending ip addresses index page" do
        it "responds successfully" do
          expect(response).to be_successful
        end

        it "assigns the @petition instance variable" do
          expect(assigns(:petition)).to eq(petition)
        end

        it "assigns the @trending_ips instance variable" do
          expect(assigns(:trending_ips)).to eq(trending_ips)
        end

        it "renders the trending_ips/index template" do
          expect(response).to render_template("trending_ips/index")
        end
      end

      context "when viewing all trending ip addresses" do
        before do
          expect(scope).to receive(:search).with(nil, page: nil).and_return(trending_ips)
          get :index, params: { petition_id: "200000" }
        end

        include_examples("trending ip addresses index page")
      end

      context "when viewing page 2 of all trending ip addresses" do
        before do
          expect(scope).to receive(:search).with(nil, page: "2").and_return(trending_ips)
          get :index, params: { petition_id: "200000", page: "2" }
        end

        include_examples("trending ip addresses index page")
      end

      context "when searching trending ip addresses" do
        before do
          expect(scope).to receive(:search).with("127.0.0.1", page: nil).and_return(trending_ips)
          get :index, params: { petition_id: "200000", q: "127.0.0.1" }
        end

        include_examples("trending ip addresses index page")
      end

      context "when viewing page 2 of a trending ip addresses search" do
        before do
          expect(scope).to receive(:search).with("127.0.0.1", page: "2").and_return(trending_ips)
          get :index, params: { petition_id: "200000", q: "127.0.0.1", page: "2" }
        end

        include_examples("trending ip addresses index page")
      end
    end
  end
end
