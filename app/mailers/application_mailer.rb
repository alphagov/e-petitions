class ApplicationMailer < ActionMailer::Base
  default_url_options[:protocol] = AppConfig.email_protocol

  layout 'default_mail'
  default :from => AppConfig.email_from
end
