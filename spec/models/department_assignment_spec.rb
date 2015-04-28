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
      expect(department_assignment.valid?).not_to be_truthy
      expect(department_assignment.errors_on(:petition).size).to eq(1)
    end

    it "requires a department" do
      department_assignment = DepartmentAssignment.new(:department => nil)
      expect(department_assignment.valid?).not_to be_truthy
      expect(department_assignment.errors_on(:department).size).to eq(1)
    end

    it "requires an assigned_on timestamp" do
      department_assignment = DepartmentAssignment.new(:assigned_on => nil)
      expect(department_assignment.valid?).not_to be_truthy
      expect(department_assignment.errors_on(:assigned_on).size).to eq(1)
    end
  end
end
