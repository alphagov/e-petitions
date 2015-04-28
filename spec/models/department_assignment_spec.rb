# == Schema Information
#
# Table name: department_assignments
#
#  id            :integer(4)      not null, primary key
#  petition_id   :integer(4)
#  department_id :integer(4)
#  assigned_on   :datetime
#  created_at    :datetime
#  updated_at    :datetime
#

require 'rails_helper'

describe DepartmentAssignment do
  describe "validations" do
    it "requires a petition" do
      department_assignment = DepartmentAssignment.new(:petition => nil)
      department_assignment.valid?.should_not be_true
      department_assignment.should have(1).errors_on(:petition)
    end

    it "requires a department" do
      department_assignment = DepartmentAssignment.new(:department => nil)
      department_assignment.valid?.should_not be_true
      department_assignment.should have(1).errors_on(:department)
    end

    it "requires an assigned_on timestamp" do
      department_assignment = DepartmentAssignment.new(:assigned_on => nil)
      department_assignment.valid?.should_not be_true
      department_assignment.should have(1).errors_on(:assigned_on)
    end
  end
end
