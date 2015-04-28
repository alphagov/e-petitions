require 'rails_helper'

describe DepartmentsController do

  describe "GET 'index'" do
    let(:departments) { mock }

    it "should assign departments" do
      Department.stub(:all).and_return(departments)

      get 'index'

      response.should be_success
      assigns(:departments).should == departments
    end
  end

  describe "GET 'show'" do
    it "should assign department" do
      department = FactoryGirl.create(:department)
      get 'show', :id => department.id.to_s
      assigns(:department).should == department
    end
  end

  describe "info" do
    it "should respond to /departments/info" do
      {:get => '/departments/info'}.should route_to({:controller => 'departments', :action => 'info'})
      info_departments_path.should == '/departments/info'
    end

    it "should assign @departments" do
      d1 = FactoryGirl.create(:department)
      d2 = FactoryGirl.create(:department)
      get :info
      assigns[:departments].should == [d1, d2]
    end
  end
end
