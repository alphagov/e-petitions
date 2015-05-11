class ApplicationMailer < ActionMailer::Base
  helper :link

  layout 'default_mail'
  default :from => AppConfig.email_from
end
