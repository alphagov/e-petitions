class Admin::UserSessionsController < Admin::AdminController
  skip_before_filter :require_admin, only: [:new, :create]
  skip_before_filter :check_for_password_change

  def new
    @user_session = AdminUserSession.new
  end

  def create
    @user_session = AdminUserSession.new(params[:admin_user_session])

    if @user_session.save
      redirect_to_target_or_default
    elsif @user_session.last_login_attempt?
      render :new, alert: :last_login
    elsif @user_session.being_brute_force_protected?
      render :new, alert: :disabled_login
    else
      render :new, alert: :invalid_login
    end
  end

  def destroy
    current_session.destroy if logged_in?
    redirect_to admin_login_url, notice: :logged_out
  end
end
