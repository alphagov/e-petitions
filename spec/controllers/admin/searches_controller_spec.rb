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
            expect(assigns(:search_type)).to eq "keyword"
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

      context "searching for signatures" do
        let(:signatures) { double }

        shared_examples "a signature search" do |search_type, sig_method|
          it "returns an array of signatures" do
            allow(signatures).to receive_messages(paginate: signatures)
            allow(Signature).to receive_messages(sig_method => signatures)
            get :show, q: '', search_type: search_type
            expect(assigns(:signatures)).to eq(signatures)
          end
        end

        context "by name" do
          let(:query) { "Joe Bloggs" }
          let(:search_type) { "sig_name" }

          it_behaves_like "a signature search", "sig_name", :for_name
          it_behaves_like "it sets instance variables"
        end

        context "by email address" do
          let(:query) { "joe.bloggs@unboxed.com" }
          let(:search_type) { "sig_email" }

          it_behaves_like "a signature search", "sig_email", :for_email
          it_behaves_like "it sets instance variables"
        end

        context "by IP address" do
          let(:query) { "192.168.1.1" }
          let(:search_type) { "ip_address" }

          it_behaves_like "a signature search", "ip_address", :for_ip
          it_behaves_like "it sets instance variables"
        end
      end

      context "searching for petition by id" do
        let(:petition) { double(id: 123, to_param: '123') }
        let(:search_type) { "petition_id" }
        let(:query) { "123" }

        before do
          allow(Petition).to receive_messages(find: petition)
        end

        it_behaves_like "it sets instance variables"

        it "redirects to a petition if the id exists" do
          get :show, q: query, search_type: search_type
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        context "when petition not found" do
          before do
            allow(Petition).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
          end

          it "renders the form with an error" do
            get :show, q: query, search_type: search_type
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions")
          end

          it "sets the flash error" do
            get :show, q: query, search_type: search_type
            expect(flash[:alert]).to match(/123/)
          end
        end
      end

      context "searching by keyword" do
        let(:search_type) { "keyword" }
        let(:query) { "example query" }

        it_behaves_like "it sets instance variables"

        it "redirects to the all petitions page" do
          get :show, q: query, search_type: search_type, tag_filters: tag_filters
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions?q=example+query&search_type=keyword&tag_filters%5B%5D=tag+1&tag_filters%5B%5D=tag+2")
        end
      end

      context "searching by tag" do
        let(:search_type) { "tag" }
        let(:query) { "tag 1"}

        it_behaves_like "it sets instance variables"

        it "redirects to the all petitions page" do
          get :show, q: query, search_type: search_type, tag_filters: tag_filters
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions?q=tag+1&search_type=tag&tag_filters%5B%5D=tag+1&tag_filters%5B%5D=tag+2")
        end
      end
    end
  end
end
