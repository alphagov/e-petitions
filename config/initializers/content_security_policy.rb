# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self

    policy.connect_src :self,
      "https://www.google-analytics.com"

    policy.img_src :self,
      "https://www.google-analytics.com"

    policy.script_src :self, :unsafe_inline,
      "https://www.googletagmanager.com",
      "https://www.google-analytics.com"

    policy.style_src :self, :unsafe_inline
  end
end
