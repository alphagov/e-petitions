class Admin::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :require_admin
  skip_before_action :verify_authenticity_token, only: %i[saml]

  before_action :find_identity_provider, only: :saml
  before_action :verify_authentication_data, only: :saml

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to admin_login_url, alert: :login_failed
  end

  rescue_from ActionController::BadRequest do
    redirect_to admin_login_url, alert: :invalid_login
  end

  def passthru
    raise ActionController::BadRequest, "Couldn’t find the provider '#{provider_name}'"
  end

  def saml
    @user = AdminUser.find_or_create_from!(@provider, auth_data)

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

  def provider_name
    params.fetch(:provider)
  end

  def find_identity_provider
    @provider = IdentityProvider.find_by!(name: provider_name)
  rescue IdentityProvider::NotFoundError => e
    raise ActionController::BadRequest, "Couldn’t find the provider '#{provider_name}'"
  end

  def verify_authentication_data
    unless auth_data.present?
      raise ActionController::BadRequest, "Missing authentication data"
    end

    %w[uid provider].each do |key|
      unless auth_data[key].present?
        raise ActionController::BadRequest, "Missing authentication parameter: '#{key}'"
      end
    end

    %w[first_name last_name groups].each do |key|
      unless auth_data.info[key].present?
        raise ActionController::BadRequest, "Missing authentication info: '#{key}'"
      end
    end
  end

  def set_refresh_header
    headers['Refresh'] = "0; url=#{admin_root_url}"
  end
end
