class Admin::UserSessionsController < Admin::AdminController
  skip_before_filter :require_admin_and_check_for_password_change

  def new
    @user_session = AdminUserSession.new
  end

  def create
    @user_session = AdminUserSession.new(params[:admin_user_session])
    if @user_session.save
      redirect_to_target_or_default

    # if failed logins are above the specified level, then authlogic disables account
    # so we need to display appropriate error message
    elsif  @user_session.errors[:base].size > 0
      flash.now[:alert] = @user_session.errors[:base][0]
      render :new
    else
      flash.now[:alert] = "Invalid email/password combination"
      render :new
    end
  end

  def destroy
    current_session.destroy if logged_in?
    flash[:notice] = "You have been logged out."
    redirect_to admin_login_url
  end
end

