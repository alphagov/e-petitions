require 'rails_helper'

RSpec.describe Admin::SearchesController, type: :controller do

  describe "not logged in" do
    describe "GET 'new'" do
      it "should redirect to the login page" do
        get :new
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end
  end

  describe "logged in as moderator user" do
    before :each do
      @user = FactoryGirl.create(:moderator_user)
      login_as(@user)
    end

    describe "GET 'new'" do
      it "is successful" do
        get :new
        expect(response).to be_success
      end
      it "sets @query to blank" do
        get :new
        expect(assigns(:query)).to eq("")
      end
    end

    describe "GET 'result'" do
      context "searching for email address" do
        let(:signatures) { double }
        it "returns an array of signatures for an email address" do
          allow(signatures).to receive_messages(:paginate => signatures)
          allow(Signature).to receive_messages(:for_email => signatures)
          get :result, :search => { :query => 'something@example.com' }
          expect(assigns(:signatures)).to eq(signatures)
        end

        it "sets @query" do
          get :result, :search => { :query => 'foo bar' }
          expect(assigns(:query)).to eq("foo bar")
        end
      end

      context "searching for petition by id" do
        let(:petition) { double(:id => 123, :to_param => '123', :editable_by? => false, :response_editable_by? => false) }

        before do
          allow(Petition).to receive_messages(:find => petition)
        end

        it "redirects to a petition if the id exists" do
          get :result, :search => { :query => '123' }
          expect(response).to redirect_to("https://petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        context "when petition not found" do
          before do
            allow(Petition).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
          end

          it "renders the form with an error" do
            get :result, :search => { :query => '123' }
            expect(response).to redirect_to("https://petition.parliament.uk/admin/search/new")
          end

          it "sets the flash error" do
            get :result, :search => { :query => '123' }
            expect(flash[:error]).to match(/123/)
          end
        end
      end

      context "searching by keyword" do
        it "redirects to the all petitions page for a keyword" do
          get :result, :search => { :query => 'example_keyword' }
          expect(response).to redirect_to("https://petition.parliament.uk/admin/petitions?q=example_keyword")
        end
      end
    end
  end
end
