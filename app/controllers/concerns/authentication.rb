# This module is included in your application controller which makes
# several methods available to all controllers and views. Here's a
# common example you might add to your application layout file.
#
#   <% if logged_in? %>
#     Welcome <%=h current_account.username %>! Not you?
#     <%= link_to "Log out", logout_path %>
#   <% else %>
#     <%= link_to "Sign up", signup_path %> or
#     <%= link_to "log in", login_path %>.
#   <% end %>
#
# You can also restrict unregistered users from accessing a controller using
# a before filter. For example.
#
#   before_filter :login_required, :except => [:index, :show]
module Authentication
  def self.included(controller)
    controller.send :helper_method, :current_account, :current_user, :logged_in?, :redirect_to_target_or_default, :require_admin
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

  def login_required
    unless logged_in?
      flash[:error] = "You must first log in or sign up before accessing this page."
      store_target_location
      redirect_to admin_login_url
    end
  end

  def redirect_to_target_or_default
    redirect_to(session[:return_to] || admin_root_url)
    session[:return_to] = nil
  end

  def require_admin
    unless current_user
      flash[:error] = "You must be logged in as an administrator to view this page."
      redirect_to admin_login_url
    end
  end

  def require_admin_and_check_for_password_change
    if current_user.nil?
      flash[:error] = "You must be logged in as an administrator to view this page."
      redirect_to admin_login_url
    elsif current_user.has_to_change_password?
      flash[:error] = "Please change your password before continuing"
      redirect_to edit_admin_profile_url(current_user)
    end
  end

  def require_sysadmin
    unless current_user && current_user.is_a_sysadmin?
      flash[:error] = "You must be logged in as a system administrator to view this page."

      if current_user.is_a_moderator?
        redirect_to admin_root_url
      else
        redirect_to admin_login_url
      end
    end
  end

  private

  def store_target_location
    session[:return_to] = request.fullpath
  end
end
