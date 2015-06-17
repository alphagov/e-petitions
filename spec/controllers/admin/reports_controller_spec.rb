require 'rails_helper'

RSpec.describe Admin::ReportsController, type: :controller do

  describe "GET #index" do
    context "logged in" do
      before(:each) do
        login_as FactoryGirl.create(:moderator_user)
      end

      it "is successful" do
        get :index
        expect(response).to be_success
      end

      describe "for basic reports" do
        it "fetches a count of all open petitions" do
          expect(Petition).to receive(:counts_by_state)
          get :index
        end

        it "assigns counts by state to the view" do
          counts = double
          allow(Petition).to receive(:counts_by_state).and_return(counts)
          get :index
          expect(assigns(:counts)).to eq(counts)
        end
      end

      describe "for trending petitions" do
        let(:trending_petitions) { double }

        before do
          allow(Petition).to receive(:trending).and_return(trending_petitions)
        end

        it "assigns number_of_days_to_trend to the view" do
          get :index
          expect(assigns(:number_of_days_to_trend)).to eq(1)
        end

        it "adjusts the number of days to trend if param is passed in" do
          get :index, :number_of_days_to_trend => 7
          expect(assigns(:number_of_days_to_trend)).to eq(7)
        end

        it "assigns trending_petitions" do
          get :index
          expect(assigns(:trending_petitions)).to eq(trending_petitions)
        end
      end
    end

    context "not logged in" do
      it "redirects to the admin login path" do
        get :index
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end
  end
end
