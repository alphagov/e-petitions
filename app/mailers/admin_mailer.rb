class AdminMailer < ActionMailer::Base
  default from: -> { Site.email_from }

  def threshold_email_reminder(admin_users, petitions)
    @petitions = petitions
    mail(subject: "Petitions alert", to: admin_users.map(&:email))
  end
end
