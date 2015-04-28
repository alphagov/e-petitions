require 'rails_helper'

describe DepartmentsController do

  describe "GET 'index'" do
    let(:departments) { double }

    it "should assign departments" do
      allow(Department).to receive(:all).and_return(departments)

      get 'index'

      expect(response).to be_success
      expect(assigns(:departments)).to eq(departments)
    end
  end

  describe "GET 'show'" do
    it "should assign department" do
      department = FactoryGirl.create(:department)
      get 'show', :id => department.id.to_s
      expect(assigns(:department)).to eq(department)
    end
  end

  describe "info" do
    it "should respond to /departments/info" do
      expect({:get => '/departments/info'}).to route_to({:controller => 'departments', :action => 'info'})
      expect(info_departments_path).to eq '/departments/info'
    end

    it "should assign @departments" do
      d1 = FactoryGirl.create(:department)
      d2 = FactoryGirl.create(:department)
      get :info
      expect(assigns[:departments]).to eq [d1, d2]
    end
  end
end
