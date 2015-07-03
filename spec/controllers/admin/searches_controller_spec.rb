require 'rails_helper'

RSpec.describe Admin::SearchesController, type: :controller, admin: true do

  describe "logged in as moderator user" do
    before :each do
      @user = FactoryGirl.create(:moderator_user)
      login_as(@user)
    end

    describe "GET 'show'" do
      context "searching for email address" do
        let(:signatures) { double }
        it "returns an array of signatures for an email address" do
          allow(signatures).to receive_messages(:paginate => signatures)
          allow(Signature).to receive_messages(:for_email => signatures)
          get :show, q: 'something@example.com'
          expect(assigns(:signatures)).to eq(signatures)
        end

        it "sets @query" do
          get :show, q: 'foo bar'
          expect(assigns(:query)).to eq("foo bar")
        end
      end

      context "searching for petition by id" do
        let(:petition) { double(:id => 123, :to_param => '123') }

        before do
          allow(Petition).to receive_messages(:find => petition)
        end

        it "redirects to a petition if the id exists" do
          get :show, q: '123'
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        context "when petition not found" do
          before do
            allow(Petition).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
          end

          it "renders the form with an error" do
            get :show, q: '123'
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions")
          end

          it "sets the flash error" do
            get :show, q: '123'
            expect(flash[:error]).to match(/123/)
          end
        end
      end

      context "searching by keyword" do
        it "redirects to the all petitions page for a keyword" do
          get :show, q: 'example_keyword'
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions?q=example_keyword")
        end
      end

      context "searching by tag" do
        it "redirects to the all petitions page for a tag" do
          get :show, q: '[a tag]'
          expect(response).to redirect_to("https://petition.parliament.uk/admin/petitions?t=a+tag")
        end
      end
    end
  end
end
