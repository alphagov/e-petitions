class Admin::ReportsController < Admin::AdminController

  def index
    @counts = Petition.counts_by_state
    @departments = Department.by_petition_count

    @number_of_days_to_trend  = params[:number_of_days_to_trend].present? ? params[:number_of_days_to_trend].to_i : 1
    @trending_petitions = Petition.trending(@number_of_days_to_trend)
  end

end
