class StatisticsMailer < ApplicationMailer
  def error(user)
    @user = user

    mail to: user.rfc822, subject: "Statistics report error"
  end

  def moderation_performance(user, report)
    @user, @report = user, report
    attachments[report.filename] = report.attachment

    mail to: user.rfc822, subject: "Moderation performance report"
  end

  def signature_counts(user, report)
    @user, @report = user, report
    attachments[report.filename] = report.attachment

    mail to: user.rfc822, subject: "Signature count report"
  end
end
