require 'rails_helper'

RSpec.describe Admin::SearchesController, type: :controller, admin: true do
  describe "logged in as moderator user" do
    before :each do
      @user = FactoryGirl.create(:moderator_user)
      login_as(@user)
    end

    describe "GET 'show'" do
      let(:tag_filters) { ["tag 1", "tag 2"] }

      shared_examples "it sets instance variables" do
        context "search_type not present" do
          it "defaults the search type to 'keyword'" do
            get :show
            expect(assigns(:search_type)).to eq "petition"
          end
        end

        it "sets @search_type" do
          get :show, search_type: search_type
          expect(assigns(:search_type)).to eq search_type
        end

        context "tag filters not present" do
          it "defaults tag filters to an empty array" do
            get :show
            expect(assigns(:tag_filters)).to eq []
          end
        end

        it "sets @tag_filters" do
          get :show, tag_filters: tag_filters
          expect(assigns(:tag_filters)).to eq tag_filters
        end

        context "query is not present" do
          it "defaults query to empty string" do
            get :show
            expect(assigns(:query)).to eq ''
          end
        end

        it "sets @query" do
          get :show, q: query
          expect(assigns(:query)).to eq(query)
        end
      end

      context "searching for petition by id" do
        let(:petition) { double(id: 123, to_param: '123') }
        let(:query) { "123" }
        let(:search_type) { "signature" }

        before do
          allow(Petition).to receive_messages(find: petition)
        end

        it_behaves_like "it sets instance variables"

        it "redirects to a petition if the id exists" do
          get :show, q: query
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        it "ignores the search type param" do
          get :show, q: query, search_type: search_type
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        context "when petition not found" do
          before do
            allow(Petition).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
          end

          it "renders the form with an error" do
            get :show, q: query
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions")
          end

          it "sets the flash error" do
            get :show, q: query
            expect(flash[:alert]).to match(/123/)
          end
        end
      end

      context "searching for signatures" do
        let(:search_type) { "signature" }
        let(:query) { "test@email.com" }

        it_behaves_like "it sets instance variables"

        it "redirects to admin signature index path" do
          get :show, q: query, search_type: search_type
          expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/signatures?q=test%40email.com"
        end

        it "ignores any tag filters in the params" do
          get :show, q: query, search_type: search_type, tag_filters: tag_filters
          expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/signatures?q=test%40email.com"
        end
      end

      context "searching for petitions" do
        let(:search_type) { "petitions" }
        let(:query) { "example query" }

        it_behaves_like "it sets instance variables"

        it "redirects to the admin petitions index path" do
          get :show, q: query, search_type: search_type, tag_filters: tag_filters
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions?q=example+query&tag_filters%5B%5D=tag+1&tag_filters%5B%5D=tag+2")
        end
      end
    end
  end
end
