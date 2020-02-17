require 'active_support/concern'

module Departments
  extend ActiveSupport::Concern

  included do
    validate :departments_exist
  end

  class_methods do
    def all_departments(*departments)
      where(departments_column.contains(normalize_departments(departments)))
    end
    alias_method :for_department, :all_departments

    def any_departments(*departments)
      where(departments_column.overlaps(normalize_departments(departments)))
    end

    def with_department
      where(departments_column.not_eq([]))
    end

    def without_department
      where(departments_column.eq([]))
    end

    def departments_column
      arel_table[:departments]
    end

    def normalize_departments(departments)
      Array(departments).flatten.map(&:to_i).compact.reject(&:zero?)
    end
  end

  def normalize_departments(departments)
    self.class.normalize_departments(departments)
  end

  def departments=(departments)
    super(normalize_departments(departments))
  end

  def depts
    Department.where(id: departments).order(:name).to_a
  end

  def department_names
    Department.where(id: departments).order(:name).pluck(:name)
  end

  def departments_exist
    unless departments.all? { |department| Department.exists?(department) }
      errors.add :departments, :invalid
    end
  end
end
