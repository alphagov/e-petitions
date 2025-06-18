# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self

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
      "https://*.googletagmanager.com"

    policy.style_src :self, :unsafe_inline
    policy.style_src_attr :self, :unsafe_inline
  end
end

Rails.application.config.content_security_policy_nonce_generator = -> (request) { SecureRandom.base64(15) }
