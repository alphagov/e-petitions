class PublicController < ApplicationController
  content_security_policy do |policy|
    if Site.enable_analytics?
      policy.connect_src :self,
        "https://*.google-analytics.com",
        "https://*.analytics.google.com",
        "https://*.googletagmanager.com"

      policy.frame_src :self,
        "https://*.google-analytics.com",
        "https://*.googletagmanager.com"

      policy.img_src :self,
        "https://*.google-analytics.com",
        "https://*.googletagmanager.com"

      policy.script_src :self,
        "https://*.googletagmanager.com",
        "'#{Site.google_tag_manager_hash}'"
    else
      policy.script_src :self
    end
  end
end
