class AdminMailer < ActionMailer::Base
  default from: ->(email){ Site.email_from }

  def threshold_email_reminder(admin_users, petitions)
    @petitions = petitions
    mail(subject: "e-Petitions alert", to: admin_users.map(&:email))
  end
end
