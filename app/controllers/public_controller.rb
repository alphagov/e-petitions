class PublicController < ApplicationController
  before_action :service_unavailable, unless: :site_enabled?
  before_action :authenticate, if: :site_protected?

  content_security_policy do |policy|
    if Site.enable_analytics?
      policy.connect_src :self,
        "https://*.google-analytics.com",
        "https://*.analytics.google.com",
        "https://*.googletagmanager.com"

      policy.frame_src :self,
        "https://www.youtube-nocookie.com",
        "https://*.google-analytics.com",
        "https://*.googletagmanager.com"

      policy.img_src :self, :data,
        "https://*.ytimg.com",
        "https://*.google-analytics.com",
        "https://*.googletagmanager.com"

      policy.script_src :self,
        "https://*.googletagmanager.com",
        "'#{Site.google_tag_manager_hash}'"
    else
      policy.frame_src :self, "https://www.youtube-nocookie.com"
      policy.img_src :self, :data, "https://*.ytimg.com"
      policy.script_src :self
    end
  end

  helper_method :public_petition_facets

  private

  def authenticate
    unless authenticated?
      if request.format.html?
        redirect_to login_url
      else
        head :forbidden
      end
    end
  end

  def authenticated?
    cookies[:login] == Site.login_digest
  end

  def service_unavailable
    unless authenticated?
      raise Site::ServiceUnavailable, "Sorry, the website is temporarily unavailable"
    end
  end

  def site_enabled?
    Site.enabled?
  end

  def site_protected?
    Site.protected? unless request.local?
  end

  def public_petition_facets
    I18n.t('public', scope: :"petitions.facets")
  end
end
