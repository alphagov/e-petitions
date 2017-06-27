require 'rails_helper'

RSpec.describe Archived::PetitionsController, type: :controller do
  let!(:parliament) { FactoryGirl.create(:parliament, :archived) }

  describe "GET #index" do
    context "when no state param is provided" do
      it "is successful" do
        get :index
        expect(response).to be_success
      end

      it "exposes a search scoped to the all facet" do
        get :index
        expect(assigns(:petitions).scope).to eq :all
      end
    end

    context "when a state param is provided" do
      context "but it is not a public facet from the locale file" do
        it "redirects to itself with state=all" do
          get :index, state: "awaiting_monkey"
          expect(response).to redirect_to "https://petition.parliament.uk/archived/petitions?state=all"
        end

        it "preserves other params when it redirects" do
          get :index, q: "what is clocks", state: "awaiting_monkey"
          expect(response).to redirect_to "https://petition.parliament.uk/archived/petitions?q=what+is+clocks&state=all"
        end
      end

      context "and it is a public facet from the locale file" do
        it "is successful" do
          get :index, state: "published"
          expect(response).to be_success
        end

        it "exposes a search scoped to the state param" do
          get :index, state: "published"
          expect(assigns(:petitions).scope).to eq :published
        end
      end
    end
  end
end
