module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_admin

    alias_method :logged_in?, :user_signed_in?
    helper_method :logged_in?
  end

  def require_admin
    unless current_user
      redirect_to admin_login_url, alert: :admin_required
    end
  end

  def require_moderator
    unless current_user.is_a_moderator? || current_user.is_a_sysadmin?
      redirect_to admin_root_url, alert: :moderator_required
    end
  end

  def require_sysadmin
    unless current_user.is_a_sysadmin?
      redirect_to admin_root_url, alert: :sysadmin_required
    end
  end
end
