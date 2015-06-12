class ApplicationMailer < ActionMailer::Base
  default_url_options[:protocol] = Site.email_protocol

  layout 'default_mail'
  default :from => Site.email_from
end
