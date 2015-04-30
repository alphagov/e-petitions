class Admin::AdminUsersController < Admin::AdminController
  before_filter :require_sysadmin
  before_filter :assign_departments, :only => [:new, :edit]

  def index
    @users = AdminUser.by_name.paginate(:page => params[:page], :per_page => 20)
  end

  def new
    @user = AdminUser.new
  end

  def create
    @user = AdminUser.create(admin_user_params)
    update_departments(@user)
    if @user.save
      flash[:notice] = "User was successfully created"
      redirect_to admin_admin_users_path
    else
      assign_departments
      render :action => 'new'
    end
  end

  def edit
    @user = AdminUser.find(params[:id])
  end

  def update
    @user = AdminUser.find(params[:id])

    update_departments(@user)
    if @user.update_attributes(admin_user_params)
      flash[:notice] = "User was successfully updated"
      redirect_to admin_admin_users_path
    else
      assign_departments
      render :action => 'edit'
    end
  end

  def destroy
    @user = AdminUser.find(params[:id])

    # only destroy if user is not the logged in user and there are at least 2 users
    if @user == current_user
      flash[:error] = "You are not allowed to delete yourself!"
    elsif AdminUser.count < 2
      flash[:error] = "There needs to be at least 1 admin user"
    else
      @user.destroy
    end
    redirect_to admin_admin_users_path
  end

  protected

  def update_departments(user)
    department_ids = params[:department_ids].values
    # loop through backwards so deleting has no effect on subsequent elements
    user.departments.reverse.each do |department|
      user.departments.delete(department) unless department_ids.include?(department.id.to_s)
    end
    department_ids.map { |department_id| Department.find_by(id: department_id) }.compact.each do |department|
      user.departments << department unless user.departments.include?(department)
    end
  end

  def admin_user_params
    params.
      require(:admin_user).
      permit(:password, :password_confirmation, :first_name,
             :last_name, :role, :email, :force_password_reset,
             :account_disabled)
  end
end
