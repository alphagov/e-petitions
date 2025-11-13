# Be sure to restart your server when you modify this file.

# Define an application-wide HTTP permissions policy. For further
# information see: https://developers.google.com/web/updates/2018/06/feature-policy

Rails.application.config.permissions_policy do |policy|
  policy.camera      :none
  policy.gyroscope   :self, "https://www.youtube.com"
  policy.microphone  :none
  policy.usb         :none
  policy.fullscreen  :self, "https://www.youtube.com"
  policy.payment     :none
end
