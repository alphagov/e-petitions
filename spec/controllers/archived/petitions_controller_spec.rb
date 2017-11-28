require 'rails_helper'

RSpec.describe Archived::PetitionsController, type: :controller do
  let!(:parliament) { FactoryBot.create(:parliament, :archived) }

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
          get :index, params: { state: "awaiting_monkey" }
          expect(response).to redirect_to "https://petition.parliament.uk/archived/petitions?state=all"
        end

        it "preserves other params when it redirects" do
          get :index, params: { q: "what is clocks", state: "awaiting_monkey" }
          expect(response).to redirect_to "https://petition.parliament.uk/archived/petitions?q=what+is+clocks&state=all"
        end
      end

      context "and it is a public facet from the locale file" do
        it "is successful" do
          get :index, params: { state: "published" }
          expect(response).to be_success
        end

        it "exposes a search scoped to the state param" do
          get :index, params: { state: "published" }
          expect(assigns(:petitions).scope).to eq :published
        end
      end
    end
  end

  describe "GET #show" do
    context "when the petition is visible" do
      let!(:petition) { FactoryBot.create(:archived_petition) }

      it "assigns the given petition" do
        get :show, params: { id: petition.id }
        expect(assigns(:petition)).to eq(petition)
      end
    end

    context "when the petition is hidden" do
      let!(:petition) { FactoryBot.create(:archived_petition, :hidden) }

      it "raises a ActiveRecord::RecordNotFound error" do
        expect {
          get :show, params: { id: petition.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the petition is stopped" do
      let!(:petition) { FactoryBot.create(:archived_petition, :stopped) }

      it "raises a ActiveRecord::RecordNotFound error" do
        expect {
          get :show, params: { id: petition.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the petition is archived but the parliament is not" do
      let!(:parliament) { FactoryBot.create(:parliament) }
      let!(:petition) { FactoryBot.create(:archived_petition, parliament: parliament) }

      it "redirects to the current petition" do
        get :show, params: { id: petition.id }
        expect(response).to redirect_to "https://petition.parliament.uk/petitions/#{petition.id}"
      end
    end
  end
end
