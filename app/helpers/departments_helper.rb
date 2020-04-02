module DepartmentsHelper
  def departments(ids)
    @department_map ||= Department.map

    ids.inject([]) do |departments, id|
      if department = @department_map[id]
        departments << department
      end

      departments
    end.sort_by(&:name)
  end
end
