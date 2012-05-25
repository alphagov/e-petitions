class AdminMailer < ActionMailer::Base
  default :from => AppConfig.email_from

  def admin_email_reminder(admin_user, petitions, new_petitions_count)
    @admin_user = admin_user
    @petitions = petitions
    @new_petitions_count = new_petitions_count
    mail(:subject => "e-Petitions alert", :to => admin_user.email)
  end
  
  def threshold_email_reminder(admin_users, petitions)
    @petitions = petitions
    mail(:subject => "e-Petitions alert", :to => admin_users.map(&:email))
  end
end