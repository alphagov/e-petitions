# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self

    policy.connect_src :self
    policy.img_src :self
    policy.script_src :self, :unsafe_inline
    policy.style_src :self, :unsafe_inline
  end
end
