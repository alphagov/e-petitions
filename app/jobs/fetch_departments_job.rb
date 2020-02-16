class FetchDepartmentsJob < ApplicationJob
  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  def perform
    departments.each do |external_id, name, acronym, url, start_date, end_date|
      begin
        Department.for(external_id) do |department|
          department.update!(
            name: name, acronym: acronym, url: url,
            start_date: start_date, end_date: end_date
          )
        end
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end
  end

  private

  def departments
    @departments ||= Feed::Departments.new
  end
end
