class DepartmentsController < ApplicationController
  before_filter :sanitise_page_param, :only => :show
  caches_action :index, :info, :expires_in => DEFAULT_CACHE_EXPIRY

  respond_to :html

  def index
    respond_with @departments = Department.all
  end

  def show
    @department = Department.find(params[:id])
    @petition_search = DepartmentPetitionSearch.new(params)
    respond_with @department
  end

  def info
    respond_with @departments = Department.all
  end
end
