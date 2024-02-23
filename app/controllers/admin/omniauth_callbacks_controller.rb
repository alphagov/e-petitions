class Admin::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :require_admin
  skip_before_action :verify_authenticity_token, only: %i[saml]

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to admin_login_url, alert: :login_failed
  end

  def saml
    @user = AdminUser.find_or_create_from!(provider, auth_data)

    if @user.present?
      sign_in @user, event: :authentication

      set_flash_message(:notice, :signed_in)
      set_refresh_header

      render "admin/admin/index"
    else
      redirect_to admin_login_url, alert: :invalid_login
    end
  end

  def failure
    redirect_to admin_login_url, alert: :login_failed
  end

  private

  def after_omniauth_failure_path_for(scope)
    admin_login_url
  end

  def auth_data
    request.env["omniauth.auth"]
  end

  def provider
    IdentityProvider.find_by!(name: auth_data.provider)
  end

  def set_refresh_header
    headers['Refresh'] = "0; url=#{admin_root_url}"
  end
end
