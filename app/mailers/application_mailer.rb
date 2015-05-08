class ApplicationMailer < ActionMailer::Base
  layout 'default_mail'
  default :from => AppConfig.email_from
end
