class Admin::ReportsController < Admin::AdminController

  def index
    @counts = Petition.counts_by_state
    @departments = Department.by_petition_count

    departments_for_trending = current_user.can_see_all_trending_petitions? ? Department.all : current_user.departments
    @number_of_days_to_trend  = params[:number_of_days_to_trend].present? ? params[:number_of_days_to_trend].to_i : 1
    @trending_petitions = Petition.for_departments(departments_for_trending).trending(@number_of_days_to_trend)
  end

end
