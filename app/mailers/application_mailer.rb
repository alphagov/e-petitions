class ApplicationMailer < ActionMailer::Base
  default_url_options[:protocol] = Site.email_protocol
  default from: ->(email){ Site.email_from }

  helper :date_time, :rejection, :auto_link, :markdown

  layout 'default_mail'
end
