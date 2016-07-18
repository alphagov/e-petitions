class EmailThresholdReminderJob < ActiveJob::Base
  queue_as :high_priority

  def perform
    EmailReminder.threshold_email_reminder
  end
end
