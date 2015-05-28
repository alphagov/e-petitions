class Admin::AdminUsersController < Admin::AdminController
  before_filter :require_sysadmin

  def index
    @users = AdminUser.by_name.paginate(:page => params[:page], :per_page => 20)
  end

  def new
    @user = AdminUser.new
  end

  def create
    @user = AdminUser.create(admin_user_params)
    if @user.save
      flash[:notice] = "User was successfully created"
      redirect_to admin_admin_users_url
    else
      render :action => 'new'
    end
  end

  def edit
    @user = AdminUser.find(params[:id])
  end

  def update
    @user = AdminUser.find(params[:id])
    if @user.update_attributes(admin_user_params)
      flash[:notice] = "User was successfully updated"
      redirect_to admin_admin_users_url
    else
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
    redirect_to admin_admin_users_url
  end

  protected

  def admin_user_params
    params.
      require(:admin_user).
      permit(:password, :password_confirmation, :first_name,
             :last_name, :role, :email, :force_password_reset,
             :account_disabled)
  end
end
