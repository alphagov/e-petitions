class Admin::SessionsController < Devise::SessionsController
  skip_before_action :require_admin, except: :continue
  prepend_before_action :skip_timeout, only: :status

  helper_method :last_request_at

  def create
    if provider?
      redirect_to sso_provider_url(provider), status: :temporary_redirect
    else
      redirect_to admin_login_url, alert: :invalid_login
    end
  end

  def continue
    respond_to do |format|
      format.json
    end
  end

  def status
    respond_to do |format|
      format.json
    end
  end

  private

  def email_domain
    Mail::Address.new(sign_in_params[:email]).domain
  rescue Mail::Field::ParseError
    nil
  end

  def provider
    @provider ||= IdentityProvider.find_by(domain: email_domain)
  end

  def provider?
    provider.present?
  end

  def skip_timeout
    request.env['devise.skip_trackable'] = true
  end

  def last_request_at
    if user_session && user_session.key?("last_request_at")
      Time.at(user_session["last_request_at"]).in_time_zone
    end
  end
end
