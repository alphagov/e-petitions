require 'rails_helper'

RSpec.describe Archived::PetitionsController, type: :controller do
  let!(:parliament) { FactoryBot.create(:parliament, :archived) }

  describe "GET #index" do
    context "when no state param is provided" do
      it "is successful" do
        get :index
        expect(response).to be_successful
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
          expect(response).to be_successful
        end

        it "exposes a search scoped to the state param" do
          get :index, params: { state: "published" }
          expect(assigns(:petitions).scope).to eq :published
        end
      end

      context "and it is an array" do
        it "redirects to itself with state=all" do
          get :index, params: { state: [ "l337haxxor" ] }
          expect(response).to redirect_to "https://petition.parliament.uk/archived/petitions?state=all"
        end

        it "preserves other params when it redirects" do
          get :index, params: { q: "what is clocks", state: [ "l337haxxor" ] }
          expect(response).to redirect_to "https://petition.parliament.uk/archived/petitions?q=what+is+clocks&state=all"
        end
      end

      context "and it is a hash" do
        it "redirects to itself with state=all" do
          get :index, params: { state: { l337: "haxxor" } }
          expect(response).to redirect_to "https://petition.parliament.uk/archived/petitions?state=all"
        end

        it "preserves other params when it redirects" do
          get :index, params: { q: "what is clocks", state: { l337: "haxxor" } }
          expect(response).to redirect_to "https://petition.parliament.uk/archived/petitions?q=what+is+clocks&state=all"
        end
      end
    end

    context "when a page param is provided" do
      context "and it is an array" do
        it "is treated as being on the first page" do
          get :index, params: { page: [ "l337haxxor" ] }
          expect(assigns(:petitions).current_page).to eq 1
        end
      end

      context "and it is a hash" do
        it "is treated as being on the first page" do
          get :index, params: { page: { l337: "haxxor" } }
          expect(assigns(:petitions).current_page).to eq 1
        end
      end

      context "and it is out of range" do
        it "is treated as being on the first page" do
          get :index, params: { page: "414141414141414141" }
          expect(assigns(:petitions).current_page).to eq 1
        end
      end
    end

    context "when a count param is provided" do
      context "and it is an array" do
        it "uses the default count" do
          get :index, params: { count: [ "l337haxxor" ] }
          expect(assigns(:petitions).page_size).to eq 50
        end
      end

      context "and it is a hash" do
        it "uses the default count" do
          get :index, params: { count: { l337: "haxxor" } }
          expect(assigns(:petitions).page_size).to eq 50
        end
      end

      context "and it is out of range" do
        it "uses the default count" do
          get :index, params: { count: "414141414141414141" }
          expect(assigns(:petitions).page_size).to eq 50
        end
      end
    end

    context "when a parliament parameter is provided" do
      let(:parliament) { FactoryBot.create(:parliament, :coalition) }

      it "assigns the @parliament instance variable" do
        get :index, params: { parliament: parliament.id }
        expect(assigns(:parliament)).to eq(parliament)
      end

      context "when the parliament parameter is not a number" do
        it "raises a ActionController::BadRequest error" do
          expect {
            get :index, params: { parliament: "notanumber" }
          }.to raise_error(ActionController::BadRequest)
        end
      end

      context "when the parliament parameter is an array" do
        it "raises a ActionController::BadRequest error" do
          expect {
            get :index, params: { parliament: [1] }
          }.to raise_error(ActionController::BadRequest)
        end
      end

      context "when the parliament parameter is a hash" do
        it "raises a ActionController::BadRequest error" do
          expect {
            get :index, params: { parliament: { id: 1 } }
          }.to raise_error(ActionController::BadRequest)
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
