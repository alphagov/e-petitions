class Admin::AdminUsersController < Admin::AdminController
  before_filter :require_sysadmin
  before_filter :find_user, only: %i[edit update destroy]

  rescue_from AdminUser::CannotDeleteCurrentUser do
    redirect_to admin_admin_users_url, alert: :user_is_current_user
  end

  rescue_from AdminUser::MustBeAtLeastOneAdminUser do
    redirect_to admin_admin_users_url, alert: :user_count_is_too_low
  end

  def index
    @users = AdminUser.by_name.paginate(page: params[:page], per_page: 50)
  end

  def new
    @user = AdminUser.new
  end

  def create
    @user = AdminUser.new(admin_user_params)

    if @user.save
      redirect_to admin_admin_users_url, notice: :user_created
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update(admin_user_params)
      redirect_to admin_admin_users_url, notice: :user_updated
    else
      render :edit
    end
  end

  def destroy
    if @user.destroy(current_user: current_user)
      redirect_to admin_admin_users_url, notice: :user_deleted
    else
      redirect_to admin_admin_users_url, alert: :user_not_deleted
    end
  end

  protected

  def find_user
    @user = AdminUser.find(params[:id])
  end

  def admin_user_params
    params.
      require(:admin_user).
      permit(:password, :password_confirmation, :first_name,
             :last_name, :role, :email, :force_password_reset,
             :account_disabled)
  end
end
