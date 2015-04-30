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

class DepartmentAssignment < ActiveRecord::Base
  belongs_to :petition
  belongs_to :department

  validates_presence_of :assigned_on, :department, :petition
end
