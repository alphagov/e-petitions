class Admin::DepartmentsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_departments, only: [:index]
  before_action :find_department, only: [:edit, :update, :destroy]
  before_action :build_department, only: [:new, :create]
  before_action :destroy_department, only: [:destroy]

  def index
    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @department.save
      redirect_to_index_url notice: :department_created
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @department.update(department_params)
      redirect_to_index_url notice: :department_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def destroy
    redirect_to_index_url notice: :department_deleted
  end

  private

  def find_departments
    @departments = Department.search(params)
  end

  def find_department
    @department = Department.find(params[:id])
  end

  def build_department
    @department = Department.new(department_params)
  end

  def destroy_department
    @department.destroy
  end

  def department_params
    if params.key?(:department)
      params.require(:department).permit(:name, :acronym, :url, :start_date, :end_date)
    else
      {}
    end
  end

  def index_url
    admin_departments_url(params.permit(:q))
  end

  def redirect_to_index_url(options = {})
    redirect_to index_url, options
  end
end
