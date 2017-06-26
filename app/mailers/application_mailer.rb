class ApplicationMailer < ActionMailer::Base
  default_url_options[:protocol] = Site.email_protocol
  default from: -> { Site.email_from }

  helper :date_time, :rejection

  layout 'default_mail'
end
