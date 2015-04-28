require 'rails_helper'

describe Admin::ReportsController do

  describe "GET #index" do
    context "logged in" do
      before(:each) do
        login_as Factory(:admin_user)
      end

      with_ssl do
        it "is successful" do
          get :index
          response.should be_success
        end

        describe "for basic reports" do
          it "fetches a count of all open petitions" do
            Petition.should_receive(:counts_by_state)
            get :index
          end

          it "assigns counts by state to the view" do
            counts = double
            Petition.stub(:counts_by_state).and_return(counts)
            get :index
            assigns(:counts).should == counts
          end

          it "assigns departments to the view" do
            departments = [double]
            Department.should_receive(:by_petition_count).and_return(departments)
            get :index
            assigns(:departments).should == departments
          end
        end

        describe "for trending petitions" do
          let(:trending_petitions) { double }
          let(:all_petitions) { double(:trending => trending_petitions) }
          let(:departments) { double }

          before do
            Petition.stub(:for_departments).with(departments).and_return(all_petitions)
          end

          context "viewing as a department moderator" do
            before(:each) do
              controller.current_user.stub!(:departments).and_return(departments)
            end

            it "assigns trending petitions to those from the departments the user can access" do
              get :index
              assigns(:trending_petitions).should == trending_petitions
            end
          end

          context "viewing as someone who can see all trending petitions" do
            before(:each) do
              controller.current_user.stub(:can_see_all_trending_petitions? => true)
              Department.stub!(:all => departments)
            end

            it "assigns number_of_days_to_trend to the view" do
              get :index
              assigns(:number_of_days_to_trend).should == 1
            end

            it "adjusts the number of days to trend if param is passed in" do
              get :index, :number_of_days_to_trend => 7
              assigns(:number_of_days_to_trend).should == 7
            end

            it "assigns departments_for_trending to be all the departments" do
              get :index
              assigns(:trending_petitions).should == trending_petitions
            end
          end
        end
      end
    end

    context "not logged in" do
      with_ssl do
        it "redirects to the admin login path" do
          get :index
          response.should redirect_to(admin_login_path)
        end
      end
    end
  end

end
