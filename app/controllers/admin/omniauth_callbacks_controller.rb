class Admin::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :require_admin
  skip_before_action :verify_authenticity_token, only: %i[developer]

  def developer
    @user = AdminUser.find_by(email: omniauth_hash["uid"])

    if @user.present?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :signed_in) if is_navigational_format?
    else
      redirect_to admin_login_url, alert: :invalid_login
    end
  end

  private

  def after_omniauth_failure_path_for(scope)
    admin_login_url
  end

  def omniauth_hash
    request.env["omniauth.auth"]
  end
end
