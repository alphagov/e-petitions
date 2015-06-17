class ApplicationMailer < ActionMailer::Base
  default_url_options[:protocol] = Site.email_protocol
  default from: ->(email){ Site.email_from }

  layout 'default_mail'
end
