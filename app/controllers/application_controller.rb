class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_filter :reload_site
  before_filter :service_unavailable, unless: :site_enabled?
  before_filter :authenticate, if: :site_protected?

  before_action :set_seen_cookie_message, if: :show_cookie_message?
  helper_method :show_cookie_message?, :public_petition_facets

  protected

  def authenticate
    authenticate_or_request_with_http_basic(Site.name) do |username, password|
      Site.authenticate(username, password)
    end
  end

  def reload_site
    Site.reload
  end

  def service_unavailable
    raise Site::ServiceUnavailable, "Sorry, the website is temporarily unavailable"
  end

  def site_enabled?
    Site.enabled?
  end

  def site_protected?
    Site.protected? unless request.local?
  end

  def set_seen_cookie_message
    cookies[:seen_cookie_message] = { value: 'yes', expires: 1.year.from_now, httponly: true }
  end

  def show_cookie_message?
    @show_cookie_message ||= cookies[:seen_cookie_message] != 'yes'
  end

  def public_petition_facets
    I18n.t('public', scope: :"petitions.facets")
  end

  def do_not_cache
    response.headers['Cache-Control'] = 'no-store, no-cache'
  end
end
