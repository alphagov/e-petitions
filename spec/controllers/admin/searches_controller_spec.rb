require 'rails_helper'

RSpec.describe Admin::SearchesController, type: :controller, admin: true do

  describe "logged in as moderator user" do
    before :each do
      @user = FactoryGirl.create(:moderator_user)
      login_as(@user)
    end

    describe "GET 'show'" do
      it "defaults the search type to 'keyword'" do
        get :show
        expect(assigns(:search_type)).to eq "keyword"
      end

      it "sets @search_type" do
        get :show, search_type: "sig_name"
        expect(assigns(:search_type)).to eq "sig_name"
      end

      it "defaults tag filters to an empty array" do
        get :show
        expect(assigns(:tag_filters)).to eq []
      end

      it "sets @tag_filters" do
        tags = ["tag 1", "tag 2"]
        get :show, tag_filters: tags
        expect(assigns(:tag_filters)).to eq tags
      end

      it "defaults query to empty string" do
        get :show
        expect(assigns(:query)).to eq ''
      end

      it "sets @query" do
        get :show, q: "foo bar"
        expect(assigns(:query)).to eq("foo bar")
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
          it_behaves_like "a signature search", "sig_name", :for_name
        end

        context "by email address" do
          it_behaves_like "a signature search", "sig_email", :for_email
        end

        context "by IP address" do
          it_behaves_like "a signature search", "ip_address", :for_ip
        end
      end

      context "searching for petition by id" do
        let(:petition) { double(id: 123, to_param: '123') }
        let(:search_type) { "petition_id" }

        before do
          allow(Petition).to receive_messages(find: petition)
        end

        it "redirects to a petition if the id exists" do
          get :show, q: '123', search_type: search_type
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        context "when petition not found" do
          before do
            allow(Petition).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
          end

          it "renders the form with an error" do
            get :show, q: '123', search_type: search_type
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions")
          end

          it "sets the flash error" do
            get :show, q: '123', search_type: search_type
            expect(flash[:alert]).to match(/123/)
          end
        end
      end

      context "searching by keyword" do
        it "redirects to the all petitions page for a keyword" do
          get :show, q: "example_keyword", search_type: "keyword"
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions?q=example_keyword")
        end
      end

      context "searching by tag" do
        it "redirects to the all petitions page for a tag" do
          get :show, q: "tag 1", search_type: "tag"
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions?q=tag+1")
        end
      end
    end
  end
end
