module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_login_timeout
    before_action :logout_stale_session

    before_action :require_admin
    before_action :check_for_password_change

    helper_method :current_user, :logged_in?
  end

  def current_session
    return @current_session if defined?(@current_session)
    @current_session = AdminUserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_session && current_session.record
  end

  def logged_in?
    current_user
  end

  def redirect_to_target_or_default
    redirect_to(session[:return_to] || admin_root_url)
    session[:return_to] = nil
  end

  def require_admin
    unless current_user
      redirect_to admin_login_url, alert: :admin_required
    end
  end

  def check_for_password_change
    if current_user.has_to_change_password?
      redirect_to edit_admin_profile_url(current_user), alert: :change_password
    end
  end

  def require_sysadmin
    unless current_user.is_a_sysadmin?
      redirect_to admin_root_url, alert: :sysadmin_required
    end
  end

  private

  def store_target_location
    session[:return_to] = request.fullpath
  end

  def set_login_timeout
    AdminUser.logged_in_timeout = Site.login_timeout
  end

  def logout_stale_session
    current_session.destroy if current_session && current_session.stale?
  end
end
